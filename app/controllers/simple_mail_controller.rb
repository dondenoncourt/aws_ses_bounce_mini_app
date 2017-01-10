class SimpleMailController < ApplicationController
  skip_before_filter :verify_authenticity_token # so AWS callbacks are accepted

  def mail_it
    logger.info "mail_it called with #{params}"
    @email = params[:email]
    SimpleMailer.mail_it(@email, 'original text').deliver
    render text: 'mail sent'
  end

  def bounce
    json = JSON.parse(request.raw_post)
    logger.info "bounce callback from AWS with #{json}"
    aws_needs_url_confirmed = json['SubscribeURL']
    if aws_needs_url_confirmed
      logger.info "AWS is requesting confirmation of the bounce handler URL"
      uri = URI.parse(aws_needs_url_confirmed)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.get(uri.request_uri)
    else
      logger.info "AWS has sent us the following bounce notification(s): #{json}"
      SimpleMailer.mail_it('don@corgibytes.com', json).deliver
      json['bounce']['bouncedRecipients'].each do |recipient|
        logger.info "AWS SES received a bounce on an email send attempt to #{recipient['emailAddress']}"
      end
    end
    render nothing: true, status: 200
  end

end
