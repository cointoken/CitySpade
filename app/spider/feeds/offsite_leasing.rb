module Spider
  module Feeds
    class OffsiteLeasing < Spider::Feeds::Base
      extend Spider::Xml::Trulia
      class << self
        def provider?
          true
        end
        def feeds
          [
            'https://nestiolistings.com/feeds/1kx-13469195/cityspade.xml'
          ]
        end
        def client_name
          'OffsiteLeasing'
        end
        def default_tel
          '6466129864'
        end
        def setup
          hashes = {xmls: [], ids: []}
          callback = {
            #no_fee: true
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
