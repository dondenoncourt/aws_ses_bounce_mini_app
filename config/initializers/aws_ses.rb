# don't put your keys in free text
ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  access_key_id: ENV['ACCESS_KEY_ID'],
  secret_access_key: ENV['SECRET_ACCESS_KEY']
