class SimpleMailController < ApplicationController
  def mail_it
    @email = params[:email]
    SimpleMailer.mail_it(@email).deliver
    render text: 'mail sent'
  end

  def bounce
    puts "it bounced"
    json = JSON.parse(request.raw_post)
    if confirmation_url = json['SubscribeURL']
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
    uri = URI.parse(confirmation_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.get(uri.request_uri)
    puts "could not confirm aws sns subscription url from: #{@data}" unless response.code.to_s == '200'
  end

end
