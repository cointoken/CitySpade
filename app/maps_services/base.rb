module MapsServices
  class Logger < ActiveSupport::Logger 
    def initialize
      file = File.open("#{Rails.root}/log/maps_services.log", 'a')
      super file
    end
    def info(*arg)
      p arg
      super arg.join(' ')
    end
    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{progname} #{msg}\n"
    end
  end
  class Base
    @@limits = {}
    @@client_id = Geokit::Geocoders::GoogleGeocoder.client_id 
    @@cryptographic_key = Geokit::Geocoders::GoogleGeocoder.cryptographic_key 
    def self.limits
      @@limits
    end
    def initialize(options = {}, url = nil)
      @options = options
      @options.merge!({sensor: false, language: 'en'})
      @options[:key] ||= Settings.google_maps.server_keys.sample
      @url ||= url
      @logger = Logger.new
      @max_times = 5
    end

    def spider
      @spider ||= Spider::Base.new
    end

    def get
      @get ||= begin 
                 if @@limits[self.class.to_s] == 'false'
                   '{}'
                 else
                   res = spider.get(get_url)
                   num = 0
                   while res.code != '200' && num < @max_times
                     res = spider.get(get_url)
                     num += 1
                   end
                   content = res.body
                   json = MultiJson.load(content)
                   if ['OK', 'ZERO_RESULTS'].include? json['status']
                     content
                   else
                     @@limits[self.class.to_s] = 'false'
                     @logger.info @options
                     @logger.info get_url
                     '{}'
                   end
                 end
               end
      @logger.info @get
      @get
    end

    def allow?
      @@limits[self.class.to_s] != 'false'
    end

    def json
      @json ||= MultiJson.load(get)
    end

    def origin_json
      @origin_json ||= JSON.parse(get)
    end
    def get_url
      query  = @options.to_query
      query.gsub!('%2C', ',')
      query.gsub!('%3A', ':')
      query.gsub!('%7C', '|')
      query.gsub!('+', ' ')
      api_url = URI.escape(base_url + '?' + query)
      if @options[:key].blank? && @@client_id && @@cryptographic_key
        api_url = api_url + "&client=#{@@client_id}"
        api_url = sign_gmap_bus_api_url(api_url, @@cryptographic_key)
      end
      @logger.info api_url

      # record api count
      APICount.update class_name
      api_url
    end

    def sign_gmap_bus_api_url(origin_url, cryptographic_key)
      require 'base64'
      require 'openssl'
      origin_url = origin_url.split('maps.googleapis.com').last
      # Decode the private key
      rawKey = Base64.decode64(cryptographic_key.tr('-_','+/'))
      # create a signature using the private key and the URL
      rawSignature = OpenSSL::HMAC.digest('sha1', rawKey, origin_url)
      # encode the signature into base64 for url use form.
      signature = Base64.encode64(rawSignature).tr('+/','-_').gsub(/\n/, '')
      'https://maps.googleapis.com' + origin_url + "&signature=#{signature}"
    end

    def base_url
      @url || 'http://maps.googleapis.com/maps/api/geocode/json'
    end

    def class_name
      @class_name ||= self.class.to_s.split('::').last.downcase
    end
  end
end
