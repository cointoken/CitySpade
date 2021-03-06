module Spider
  module Feeds
    class ModaRealty < Spider::Feeds::Base
      extend Spider::Xml::Trulia
      class << self
        def provider?
          true
        end
        def feeds
          [
            'https://nestiolistings.com/feeds/1jz-328ef67a/cityspade.xml'
          ]
        end
        def client_name
          'ModaRealty'
        end
        def default_tel
          '7184120000'
        end
        def setup
          hashes = {xmls: [], ids: []}
          callback = {
            #broker: ->(broker) {
              #broker[:name].sub!('UDR', 'UDR Management')
              #if broker[:name] =~ /boston/i
                #broker[:tel] ||= '8574007812'
                #broker[:state] ||= 'MA'
              #else
                #broker[:tel] ||= '6466698347'
                #broker[:state] ||= 'NY'
              #end
              #broker
            #},
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
