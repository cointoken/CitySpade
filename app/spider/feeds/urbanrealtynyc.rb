module Spider
  module Feeds
    class Urbanrealtynyc < Spider::Feeds::Base
      extend Spider::Xml::Trulia
      class << self

        def provider?
          true
        end

        def feeds
          [
            'https://nestiolistings.com/feeds/mp-39e64ffc/cityspade.xml'
          ]
        end

        def client_name   
          'Urbanrealtynyc' 
        end

        def default_tel
          nil
        end

        def setup
          hashes = {xmls: [], ids: []}
          callback = {
            title: ->(title) { title.split('&', 2).last.strip }
            #   broker: ->(broker){
            #     broker[:name] = broker[:name].split('-').first.strip
            #     broker.delete :website
            #     broker
            #   }
            #   #no_fee: true
          }
          feeds.each do |feed|
            doc = Nokogiri::XML(RestClient.get feed)
            xmls = doc.xpath('//property')
            xmls = xmls.map{|s| s.to_hashie}
            hashes[:ids] << ids_and_urls(xmls)[:ids]
            hashes[:xmls] << xmls.map{|xml|hashie_to_listing_hash xml, callback}
          end
          hashes[:xmls].flatten!
          hashes[:ids].flatten!
          expired_listing_from_provider hashes[:ids], client_name
          hashes[:xmls].each do |xml|
            set_listing xml
          end
        end
      end
    end
  end
end
