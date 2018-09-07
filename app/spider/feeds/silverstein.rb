module Spider
  module Feeds
    class Silverstein < Spider::Feeds::Base
      extend Spider::Xml::Trulia

      class << self

        def provider?
          true
        end

        def feeds
          [
            'https://nestiolistings.com/feeds/2hh-f0bb8fe4/cityspade.xml'
          ]
        end

        def client_name
          'Silverstein'
        end

        def default_tel
          "2124734242"
        end

        def setup
            hashes = {xmls: [], ids: []}
           
            feeds.each do |feed|
              doc = Nokogiri::XML(RestClient.get feed)
              xmls = doc.xpath('//property')
              xmls = xmls.map{|s| s.to_hashie}
              hashes[:ids] << ids_and_urls(xmls)[:ids]
              hashes[:xmls] << xmls.map{|xml|hashie_to_listing_hash xml}
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
