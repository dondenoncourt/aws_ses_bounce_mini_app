Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.action_mailer.delivery_method = :ses
  config.action_mailer.default_url_options = { host: 'fast-cove-3541.herokuapp.com' }
  config.email_from_address = 'dondenoncourt@gmail.com'
  config.email_support_address = 'dondenoncourt@gmail.com'
  config.email_interceptor_to_address = 'dondenoncourt@gmail.com'
  config.intercept_emails = true
  #config.action_mailer.default_url_options = { host: ENV['HOST_URL'] }
  #config.email_from_address = ENV['EMAIL_FROM_ADDRESS']
  #config.email_support_address = ENV['EMAIL_SUPPORT_ADDRESS'] || 'support@archemedx.com'
  #config.email_interceptor_to_address = ENV['EMAIL_INTERCEPTOR_TO_ADDRESS'] # for dev only... defaults to testmail@archemedx.com
  #config.intercept_emails = true


  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
