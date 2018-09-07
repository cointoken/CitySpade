module Spider
  module SF
    class Base < Spider::Sites::Base
      def initialize(opt={})
        super
        @city_name = 'San Francisco'
        @state_name = 'CA'
      end
    end
  end
end
