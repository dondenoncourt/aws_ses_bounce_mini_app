Rails.application.routes.draw do
  root 'welcome#index'
  get 'mail_it' => 'simple_mail#mail_it'
  post 'aws_sns/bounce' => 'simple_mail#bounce'
end
