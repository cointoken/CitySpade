module Spider
  module WashingtonDC
    class Base < Spider::Sites::Base
      def initialize(opt={})
        super
        @city_name = 'Washington, D.C.'
        @state_name = 'Washington'
      end
    end
  end
end
