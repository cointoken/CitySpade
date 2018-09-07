module Spider
  module Chicago
    class Base < Spider::Sites::Base
      def initialize(opt={})
        super
        @city_name = 'Chicago'
        @state_name = 'IL'
      end
    end
  end
end
