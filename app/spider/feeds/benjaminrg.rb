module Spider
  module Feeds
    class Benjaminrg < Spider::Feeds::Base
      extend Spider::Xml::Trulia
      class << self

        def provider?
          true
        end

        def feeds
          [
            'http://benjaminrg.com/feeds/TruliaRSS-BRG.xml'
          ]
        end

        def client_name
          'Benjaminrg'
        end

        def default_tel
          "6462261554"
        end

        def setup
          hashes = {xmls: [], ids: []}
          callback = {
            title: -> (title){
              title.sub(/(\d{2})(\d{2})\s/){"#{$1}-#{$2} "}
              #street_number = title.split(/\s/).first
              #if street_number.length == 4
                #street_number = street_number.split('').in_groups_of(2,false).map{|s| s.join('')}.join("-")
                #title = title.gsub(/(^\d{2})\d{2}/, street_number)
              #end
              #title
            },
            street_address: -> (street_address){
              street_address.sub(/(\d{2})(\d{2})\s/){"#{$1}-#{$2} "}
              #street_number = street_address.split(/\s/).first
              #if street_number.length == 4
                #street_number = street_number.split('').in_groups_of(2,false).map{|s| s.join('')}.join("-")
                #street_address = street_address.gsub(/(^\d{2})\d{2}/, street_number)
              #end
              #street_address
            }
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
