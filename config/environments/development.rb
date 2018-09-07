CitySpade::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load
  config.action_mailer.delivery_method = :ses
  config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
  config.action_mailer.asset_host = "http://localhost:3000"

  # config.log_tags = [ :subdomain, :uuid, lambda { |request| request.user_agent } ]
  # Debug mode disables concatenation and preprocessing of assets.
  # ses-smtp-user.20140106-111204,AKIAJJSBDHFWUFXYRZUA,AqfTYBcA6Au3XTQtzsWwY/vLdECWCWea463SODnRDU3U
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
end
