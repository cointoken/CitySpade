module Spider
  module NYC 
    class Base < Spider::Sites::Base 
      def initialize(opt={})
        super
        @city_name = 'New York'
        @state_name = 'NY'
        @check_listing =  {zipcode: ->(code){ code =~ /(^1)|(^07)/}}
      end
    end
  end
end
