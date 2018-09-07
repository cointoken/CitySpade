require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module CitySpade
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.stylesheets false
      g.javascripts false
    end

    config.active_record.observers = :listing_image_observer

    config.autoload_paths += %W(#{config.root}/lib)

    config.to_prepare do
      require File.join(File.dirname(__FILE__), '../lib/geokit/init')
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/*/base.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/concerns/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/*/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/sites/*/base.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/spider/*/*/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/maps_services/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../app/maps_services/*/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    #config.time_zone = 'Eastern Time (US & Canada)'
    #config.active_record.default_timezone = 'Eastern Time (US & Canada)'

    config.action_mailer.delivery_method = :ses

    config.action_mailer.default_url_options = {host: 'www.cityspade.com'}
    config.assets.precompile += %w(disqus.js markerwithlabel.js infobox.js application-mobile.js application-mobile.css maps/init.js typed.js)

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
