module Spider
	module Philadelphia
		class Base < Spider::Sites::Base
			def initialize(opt={})
				super
				@city_name = 'Philadelphia'
				@state_name = 'PA'
        @check_listing =  {zipcode: ->(code){ code =~ /^19/}}
			end
		end
	end
end
