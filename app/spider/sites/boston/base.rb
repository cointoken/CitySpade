module Spider
  module Boston
    class Base < Spider::Sites::Base
      def initialize(opt)
        super
        @city_name = 'Boston'
        @state_name = 'MA'
        @check_listing =  {zipcode: ->(code){ code =~ /^02/}}
      end
    end
  end
end
