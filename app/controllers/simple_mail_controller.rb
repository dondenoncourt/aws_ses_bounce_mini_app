class SimpleMailController < ApplicationController
  skip_before_filter :verify_authenticity_token # need this for AWS callbacks

  def mail_it
    @email = params[:email]
    SimpleMailer.mail_it(@email, 'original text').deliver
    render text: 'mail sent'
  end

  def bounce
    json = JSON.parse(request.raw_post)
    aws_needs_url_confirmed = json['SubscribeURL']
    if aws_needs_url_confirmed
      puts "AWS is requesting confirmation of the bounce handler URL"
      uri = URI.parse(aws_needs_url_confirmed)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = http.get(uri.request_uri)
      puts "could not confirm aws sns subscription url from: #{@data}" unless response.code.to_s == '200'
    else
      puts "AWS has sent us a bounce notification: #{json}"
      SimpleMailer.mail_it('dondenoncourt@gmail.com', json).deliver
    end
    render nothing: true, status: 200
  end

end
