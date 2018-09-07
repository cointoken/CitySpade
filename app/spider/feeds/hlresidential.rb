module Spider
  module Feeds
    class Hlresidential < Spider::Feeds::Base
      extend Spider::Xml::Streeteasy
      class << self
        def read_obj
          RestClient.get 'http://www.hlresidential.com/feeds/streeteasy.xml'#File.read Rails.root.join('db', 'cityspade.xml')
        end
        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end
        def get_broker(xml={})
          Broker.find_and_update_from_hash(name: xml.company, website: 'http://www.hlresidential.com/', tel: '2129608740', email: 'contact@hlresidential.com')
        end
      end
    end
  end
end
