class SimpleMailer < ActionMailer::Base
  default from: "dondenoncourt@gmail.com"
  def mail_it(email, body_text)
    @email = email
    @body_text = body_text
    mail(to: email, subject: 'Simple test of AWS SES')
  end
end
