module MapsServices
  module TransportTools
    module Path
      def self.newport
        line = MtaInfoLine.where(name: 'PATH', location: 'Newport', mta_info_type: 'subway').first_or_create
        st = line.mta_info_sts.where(name: 'Newport PATH', long_name: 'Newport PATH Station').first_or_initialize
        st.target = 'subway_station'
        st.lat, st.lng = 40.726875,-74.034164
        st.save
      end
      def self.hoboken
        line = MtaInfoLine.where(name: 'PATH', location: 'Hoboken', mta_info_type: 'subway').first_or_create
        st = line.mta_info_sts.where(name: 'Hoboken PATH', long_name: 'Hoboken PATH Station').first_or_initialize
        st.target = 'subway_station'
        st.lat, st.lng = 40.7358598,-74.0292203
        st.save
      end
      def self.jerseycity
        line = MtaInfoLine.where(name: 'PATH', location: 'Exchange Place', mta_info_type: 'subway').first_or_create
        st = line.mta_info_sts.where(name: 'Jersey City PATH', long_name: 'Jersey City PATH Station').first_or_initialize
        st.target = 'subway_station'
        st.lat, st.lng = 40.7178534,-74.0341648
        st.save
      end
    end
  end
end
