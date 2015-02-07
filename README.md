== AWS SES Mini-App with Bounce Notification Handline

This README would normally document whatever steps are necessary to get the
application up and running.

a real chicken or the egg.

* The application should be coded to handle AWS confiration requests before configuring SNS
* verify email addresses first
** Services drop-down menu click on SES, under Verified Senders in the left panel, Click on Email Addresses link, Click on Verify a New Email Address button 
![Alt text](/public/images/ses_verify_email.png?raw=true)
then shows [ses_verify_email_pending.png]
** the email addressee will receive an email with:
*** Subject: Amazon SES Address Verification Request
*** body with confirmation link, click that link in the email
** a refresh on the SES Verified Senders panel should replace "pending verification" with "verified"
* create topics before...

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.


```ruby
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
      SimpleMailer.mail_it('dondenoncourt@gmail.com', json).deliver
      json['bounce']['bouncedRecipients'].each do |recipient|
        logger.info "AWS SES received a bounce on an email send attempt to #{recipient['emailAddress']}"
      end
    end
    render nothing: true, status: 200
  end

end
```

The if AWS needs URL confirmed block of the bounce method executes when
AWS-SES attempts a confirmation. That bounce method was

When an actual callback occurs. 




As promised in my last blog entry, this my first in a series of instructive Rails mini-apps. The purpose of each application will be to illustrate the use of one technique, feature, or utility. And the README with that application will be provide instructive details (https://github.com/dondenoncourt/aws_ses_bounce_mini_app).

Recently I had to code a Rails application to handle bounce notifications from AWS SES. Amazon Simple Email Server is ridiculously easy to configure and use in a Rails application. As the instructions at the github gem page, https://github.com/drewblas/aws-ses, tell you, just add the aws-ses Rails gem and create a configuration file called config/initializers/amazon_ses.rb that contains your Amazon credentials. 

But, if you need your application to handle bounce notifications, things get a little more complicated. It took me a bit to figure that out and so I wrote the mini-app and blog entry.

Let me walk through the flow of bounce notifications:

Your Rails mailer sends an email and AWS-SES fails to be able to deliver either because the email address was incorrect or the the mailbox was full or a couple other reasons covered in http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#bounce-types
You have configured AWS-SES to perform callbacks to your application when bounces occur
AWS-SES sends a POST to your application with a JSON string that contains an array of bounced email addresses

That second step, configuring AWS-SES bounce callbacks, is easier said than done. The AWS configuration screens are confusing and, to make things easy, your application should be coded to handle notifications before you do the AWS-SES configuration. 

The mini-app’s routes.rb includes the following:
```ruby
  get 'mail_it' => 'simple_mail#mail_it'
  post 'aws_sns/bounce' => 'simple_mail#bounce'
  post 'aws_sns/complaint' => 'simple_mail#complaint'
```

And here’s the controller code:

```ruby
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
      SimpleMailer.mail_it('dondenoncourt@gmail.com', json).deliver
      json['bounce']['bouncedRecipients'].each do |recipient|
        logger.info "AWS SES received a bounce on an email send attempt to #{recipient['emailAddress']}"
      end
    end
    render nothing: true, status: 200
  end

end
```

The controller’s mail_it method is self-explanatory. It take a url like: 
/mail_it?email=dondenoncourt@gmail.com
and send an email to the specified address. It is the bounce action that need a bit of explanation. As I mentioned earlier, to make AWS-SES configuration simple, your application should be configured to respond to an AWS-SES bounce callback confirmation request. Let me explain: When you configure AWS-SES bounces, you provide AWS the URL of your application. AWS will put that bounce configuration in a pending status until it is able to send a confirmation request to your application and gets a positive response. 

configure emails
sns

Click the SNS Dashboard link on the left panel and then click the Create New Topic button in the center panel. And key Topic and Display Names of “bounce” then click the Create Topic button.

![Alt text](/public/images/sns_create_bounce_topic.png?raw=true)

In the subsequent panel to be displayed
![Alt text](/public/images/sns_subscription_create_bounce.png?raw=true)
Click the Create Subscription button and key an endpoint name that matches your application’s bounce route and click the Subscribe button.

You will see a pop panel that says:
“Subscription request received!  A confirmation message will be sent to the subscribed endpoint. Once the subscription has been confirmed, the endpoint will receive notifications from this topic.  Subscriptions will expire after 3 days if not confirmed.”
![Alt text](/public/images/sns_subscription_request_bounce.png?raw=true)

Click the Close button on that popup and note the SubscriptionId column says “PendingConfirmation.” Click refresh and, if your application was available to response to the URL specified in the endpoint, the SubscriptionId should be set to a value like:

arn:aws:sns:us-east-1:294894041652:bounce:30e9ca4b-0723-4078-86a5-0d1d2573d101

Next you need to assign that SNS topic to your SES Verified Senders. 

Click on the 










aws_services_pick_sns.png







