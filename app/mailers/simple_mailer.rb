class SimpleMailer < ActionMailer::Base
  default from: "dondenoncourt@gmail.com"
  def mail_it(email)
    @email = email
    mail(to: email, subject: 'Simple test of AWS SES')
  end
end
