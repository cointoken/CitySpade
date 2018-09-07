module Spider
  module Feeds
    class JackResnick < Spider::Feeds::Base
      extend Spider::Xml::Streeteasy
      class << self
        def read_obj
          RestClient.get 'https://s3.amazonaws.com/web-webadmin/92aa9bacbb4e128c56b75e9803d3f146/production/streeteasy.xml'
        end
        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end
        def callback xml, obj = nil
          if xml.agents.try :agent
            xml.agents.agent.tel = (xml.agents.agent.phone_numbers.try(:office) || '').remove(/\D/)
          end
        end
        def get_broker(xml={})
          Broker.find_and_update_from_hash(name: 'Jack Resnick & Sons, Inc.', website: 'http://www.resnicknyc.com/')
        end
      end
    end
  end
end
