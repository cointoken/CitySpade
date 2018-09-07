module MapsServices
  module TransportTools
    class Setup
      class << self
        def init
          mta_info
          septa
          mbta
        end
        def mta_info
          MapsServices::TransportTools::MTAInfo::Subway.setup
          MapsServices::TransportTools::MTAInfo::Bus.setup
        end
        def septa
          MapsServices::TransportTools::Septa::Subway.setup
          MapsServices::TransportTools::Septa::Bus.setup
        end
        def mbta
          MapsServices::TransportTools::Mbta.setup
        end
      end
    end
  end
end
