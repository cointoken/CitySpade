module Spider
  module LA
    class Base < Spider::Sites::Base
      def initialize(opt={})
        super
        @city_name = 'Los Angeles'
        @state_name = 'CA'
      end
    end
  end
end
