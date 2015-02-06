class SimpleMailController < ApplicationController
  def mail_it
    @email = params[:email]
    SimpleMailer.mail_it(@email).deliver
    render text: 'mail sent'
  end

  def bounce
    puts "it bounced"
    @data = JSON.parse(request.raw_post)
    if confirmation_url = @data['SubscribeURL']
      _confirm_sns_subscription(confirmation_url)
    else # process bounce
      message = @data['Message']
      message = @data if message.nil? # AWS SNS payload on dev configuration did not have a Message element
      raise "could not parse aws sns bounce message from #{@data}" if message.empty?
      User.process_aws_email_bounces(message)
      Notification.process_aws_email_bounces(message)
    end
    render nothing: true, status: 200
  end
private
  def _confirm_sns_subscription(confirmation_url)
    #response = Net::HTTP.get_response(URI.parse(confirmation_url)) # can't use this b/c it's an https get request
    uri = URI.parse(confirmation_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.get(uri.request_uri)
    Rails.logger.error("could not confirm aws sns subscription url from: #{@data}") unless response.code.to_s == '200'
  end

end
