# don't put your keys in free text
ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  access_key_id: 'AKIAI2SX6L4FPN7BVXPA',
  secret_access_key: 'eJA/4eT8FmWGweAfEOhCz9b18XGDq1o46rAW2NQa'
