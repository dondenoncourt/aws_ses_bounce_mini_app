class SimpleMailController < ApplicationController
  def mail_it
    @email = params[:email]
    SimpleMailer.mail_it(@email).deliver
    render text: 'mail sent'
  end

  def bounce
    puts "it bounced"
    render text: 'it bounced'
  end
end
