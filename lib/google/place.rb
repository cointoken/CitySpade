require 'multi_json'
module Google
  class Place
    class << self
      BASE_URL = 'https://maps.googleapis.com/maps/api/place/'
      def autocomplete(input = nil, opt={})
        opts = {
          sensor: 'false',
          key: opt[:key] || Settings.google_maps.server_keys.sample,
          input: input,
          components: 'country:us'
        }.merge! opt

        APICount.update(:place)
        if Rails.env == 'production'
          to_places(get(autocomplete_url(opts)), opt[:filter] || {})
        else
          to_places(RestClient.get(autocomplete_url(opts)), opt[:filter] || {})
        end
      end
      private
      def to_places(res,filter = {})
        if res.code != '200'
          raise res.body
          return {status: '500', places:[]}
        end if Rails.env == 'production'
        body = Rails.env == 'production' ? res.body : res
        json = MultiJson.load(body, :symbolize_keys => true)
        if !['ZERO_RESULTS', 'OK'].include?(json[:status])
          raise res.body
          return {status: '500', places:[]}
        end

        places = {status: 200, places: []}
        json[:predictions].each do |place|
          if filter[:types]
            next unless filter[:types].any?{|t| place[:types].include? t}
          end
          pl = {}
          pl[:types] = place[:types]
          pl[:name] = place[:description]
          pl[:terms] = place[:terms]
          places[:places] << pl
        end
        places
      end

      def autocomplete_url(opts)
        @autocomplete_url ||= BASE_URL + 'autocomplete/json'
        # URI.escape(@autocomplete_url + "?#{opts.to_query}")
        Rails.logger.info URI.escape(@autocomplete_url + "?#{to_query(opts)}")
        URI.escape(@autocomplete_url + "?#{to_query(opts)}")
      end

      def to_query(opts)
        query = []
        opts.each do |key, value|
          query << "#{key}=#{value}" if value.present?
        end
        query.join("&")
      end

      def spider
        @spider ||= begin
                      if Rails.env != 'production'
                        Spider::Base.new proxy_host: Settings.try(:proxy_host), proxy_port: Settings.try(:proxy_port)
                      else
                        Spider::Base.new
                      end
                    end
      end
      def get(*arg)
        spider.get(*arg)
      end
    end
  end
end
