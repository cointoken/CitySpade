module Spider
  module Feeds
    class Stellarmanagement < Spider::Feeds::Base
      extend Spider::Xml::Streeteasy
      class << self
        def read_obj
          RestClient.get 'http://www.stellarmanagement.com/feed/streeteasy.aspx'
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
          Broker.find_and_update_from_hash(name: 'STELLAR MANAGEMENT INC.', website: 'http://www.stellarmanagement.com/')
        end
      end
    end
  end
end
