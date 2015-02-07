# AWS SES Mini-App with Bounce Notification Handling 

As promised in my last blog entry, this my first in a series of instructive Rails mini-apps. The purpose of each application will be to illustrate the use of one technique, feature, or utility. And the README with that application will be provide instructive details (https://github.com/dondenoncourt/aws_ses_bounce_mini_app).

Recently I had to code a Rails application to handle bounce notifications from AWS SES. Amazon Simple Email Server is ridiculously easy to configure and use in a Rails application. As the instructions at the github gem page, https://github.com/drewblas/aws-ses, tell you, just add the aws-ses Rails gem and create a configuration file called config/initializers/amazon_ses.rb that contains your Amazon credentials. 

But, if you need your application to handle bounce notifications, things get a little more complicated. It took me a bit to figure out how to properly configure AWS-SES bounce notifications and code for it in my application so I figured it would be helpful if build a mini-app with a README that details the process.

## Bounce Notification Flow

Let me walk through the flow of bounce notifications:

Your Rails mailer sends an email and AWS-SES fails to be able to deliver either because the email address was incorrect or the the mailbox was full or a couple other reasons covered in http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#bounce-types
You have configured AWS-SES to perform callbacks to your application when bounces occur
AWS-SES sends a POST to your application with a JSON string that contains an array of bounced email addresses

## Handling AWS SES Callback Confirmation HTTP Post Request

That second step, configuring AWS-SES bounce callbacks, is easier said than done. The AWS configuration screens are confusing and, to make things easy, your application should be coded to handle notifications before you do the AWS-SES configuration. 

The mini-app’s routes.rb includes the following:
```ruby
  get 'mail_it' => 'simple_mail#mail_it'
  post 'aws_sns/bounce' => 'simple_mail#bounce'
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

`/mail_it?email=dondenoncourt@gmail.com`

and responds by sending an email to the specified address. It is the bounce action that need a bit of explanation. As I mentioned earlier, to make AWS-SES configuration simple, your application should be configured to respond to an AWS-SES bounce callback confirmation request. Let me explain: When you configure AWS-SES bounces, you provide AWS the URL of your application. AWS will put that bounce configuration in a pending status until it is able to send a confirmation request to your application and gets a positive response. Anyway, I recommend that you add the route and the controller action before configuring AWS-SES.

## Heroku

I put my AWS-SES on Heroku mostly because AWS-SES callback needs to have a URL to an addressable server. My good old localhost:3000 wouldn’t work. 

## Configure Verified Senders

Now let’s configure AWS-SES. From the AWS menu, select Services and click on SES.

![Alt text](/public/images/aws_services_pick_sns.png?raw=true)

Then, on the left panel, click on Email Addresses under Verified Senders.

Click the SNS Dashboard link on the left panel and then click the Create New Topic button in the center panel. Enter Topic and Display Names of “bounce” and then click the Create Topic button.

![Alt text](/public/images/sns_create_bounce_topic.png?raw=true)

In the subsequent panel
![Alt text](/public/images/sns_subscription_create_bounce.png?raw=true)
Click the Create Subscription button and key an endpoint name that matches your application’s bounce route and click the Subscribe button.

You will see a pop panel that says:

“Subscription request received!  A confirmation message will be sent to the subscribed endpoint. Once the subscription has been confirmed, the endpoint will receive notifications from this topic.  Subscriptions will expire after 3 days if not confirmed.”

![Alt text](/public/images/sns_subscription_request_bounce.png?raw=true)

Click the Close button on that popup and note the SubscriptionId column on the page still says “PendingConfirmation.” Click refresh and, if your application was available to response to the URL specified in the endpoint, the SubscriptionId should be set to a value like:

**arn:aws:sns:us-east-1:294894041652:bounce:30e9ca4b-0723-4078-86a5-0d1d2573d101**

## Selecting the Simplified JSON Notification Format

To get a simplified version of the AWS-SES bounce JSON string I (which is also the format I expect in SimpleMailController) I changed the raw type. You should do that as well by clicking on the Subscriptions link in the left panel, then clicking the checkbox of the bounce topic in the center panel, and, in the popup, click Raw Message Delivery True, and click the Set Subscription Attributes button.

![Alt text](/public/images/sns_msg_format_raw.png?raw=true)

## Enabling Bounce Notifications

Next you need to assign the newly created “bounce” SNS topic to your SES Verified Senders. From the AWS menu, select Services and click on SES. Then, on the left panel, click on Email Addresses under Verified Senders. You had previously entered an email address here but, this time, we need to specify that emails sent through the Verified Senders will have bounce processing enabled.

![Alt text](/public/images/ses_verify_email_addr.png?raw=true)

Then click on the Verified Sender that you use as your application’s from address, expand the Notifications twirly, click on the Edit Configuration button, and, in the select box for Bounces, pick the ‘bounce’ topic you created earlier. And click the Save Config button.

![Alt text](/public/images/ses_notification_topic_selection.png?raw=true)

Note that you can configure bounce notifications by domain as well as sender email address. Also note that, after a successful bounce notification configuration, AWS post to your bounce handler an “AmazonSnsSubscriptionSucceeded” bounce notification.

## Test Bouncing

The free and default  version of AWS SES only lets you mail to verified address. So it is a bit of a problem to test bounces. But AWS provides a set of test email addresses you can use: (http://docs.aws.amazon.com/ses/latest/DeveloperGuide/mailbox-simulator.html)

From my app I used:

https://fast-cove-3541.herokuapp.com/mail_it?email=bounce@simulator.amazonses.com
The simple_mail_controller#bounce method handled that bounce by sending myself an email the body of which contains the ASW-SNS bounce JSON string:

```JSON
{"notificationType"=>"Bounce", "bounce"=>
{"bounceSubType"=>"General",
 "bounceType"=>"Permanent",
 "bouncedRecipients"=>
 [{"emailAddress"=>"bounce@simulator.amazonses.com", 
   "status"=>"5.1.1", 
   "action"=>"failed", 
   "diagnosticCode"=>"smtp; 550 5.1.1 user unknown"
 }], 
"reportingMTA"=>"dsn; a8-34.smtp-out.amazonses.com", "timestamp"=>"2015-02-07T17:40:39.338Z",
 "feedbackId"=>"0000014b65210ac9-b9f36242-8ade-413e-8597-1112a631244f-000000"}, "mail"=>{"timestamp"=>"2015-02-07T17:40:38.000Z", 
"source"=>"dondenoncourt@gmail.com", 
"destination"=>["bounce@simulator.amazonses.com"],
 "messageId"=>"0000014b652108a4-38938047-2f1b-4d2b-a1ca-28b58ed6fdd5-000000"}}
```

The JSON contains an array of bouncedReceipts. My bounce method did not really “handle” the bounce in any way other than to log the email addresses. Your application would, undoubtedly, do something a bit more useful.

Amazon lists the JSON structure for bounce notifications at http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html. You probably will want to look at the bounce types and process their handling accordingly. 

In a production application, I coded RSpec bounce handling tests with JSON built from the AWS samples.






