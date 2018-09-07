require 'rubygems'
require 'json'
require 'pp'
require 'net/http'
require 'openssl'
require 'nokogiri'

module Spider
	module NYC
		class AvalonCove < Spider::NYC::Base
			def initialize
				super
				@urlCove = "http://api.avalonbay.com/json/reply/ApartmentSearch?communityCode=NJ002"
				@uriCove = URI.parse(@urlCove)
				@dataCove = Net::HTTP.get(@uriCove)
				@docCove = JSON.parse(@dataCove)
				#Cove is just a specific building, not like the NYC community in general above.
			end

			def reformatBedroom(bedroomType)
    		firstDigit = bedroomType[0].to_f #unless bedroomType.nil?
				firstDigit
			end

			def reformatBathroom(bathroomType)
		    firstDigit = bathroomType[0].to_f
		    firstDigit
			end

			#Decide the building specs using each community code
			def retrieve_listing_basics(listingDetail, listing)
				listing[:title] = "444 Washington Boulevard"
				listing[:city_name] = "Jersey City"
				listing[:state_name] = "NJ"
				listing[:zipcode] = "07310"
				listing[:contact_tel] = "2012169200"
				listing[:description] = "Located by the historic Waterfront Walkway on the Hudson River, Avalon Cove brings a new sense of luxury living to this metropolis. Our newly renovated Jersey City apartments boast one-, two-, three- and four-bedroom designs in this bustling haven. Some of the upgrades you will find include designer gourmet kitchens with granite counters, stainless-steel appliances, hardwood floors, espresso cabinetry, marble tile bathrooms, spacious walk-in closets and private patios and balconies with great views of Manhattan. Residents can choose to spend their leisure time in the landscaped barbecue and picnic areas, at the sparkling outdoor heated swimming pool, state of the art fitness center, clubroom with billiards or at the beautiful waterfront walkway. Residents can also engage in sporting activities as our Jersey City apartments have an indoor basketball court, two lighted tennis courts and two indoor racquetball courts. Residents of our apartments in Jersey City also have access to local public transportation, on-site storage units, private garage space, gated entrance with controlled access and 24-hour maintenance service."
				listing[:amenities] = ["Granite countertops","Marble tile entries and baths","Spacious walk-in closets","24-hour emergency maintenance","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]
				return listing
			end


			def listings(options={})
			#First go through all communities in New York City and {Newport Avalon Cove}
				@docCove["results"]["availableFloorPlanTypes"].each do |floorplanTypes|
					floorplanTypes["availableFloorPlans"].each do |getDetails|
						#Bedroom Number is the same for apartments under same floorplan type
						bedroomType = getDetails["floorPlanType"]
						bathroomType = getDetails["floorPlanBathType"]
						floorplanImg1 = getDetails["floorPlanImage"]

						apartmentBlock = getDetails["finishPackages"][0]["apartments"]
						countingIndex = 0

						while (countingIndex < apartmentBlock.length) do
							apartmentBlock.each do |listingDetail|							
								listing = {}
								listing[:listing_type] = "rental"
								listing[:flag] = 1
								listing[:no_fee] = true #AvalonBay is a property management
								listing[:is_full_address] = true
								listing[:contact_name] = "AvalonBay Communities"
								listing[:beds] = reformatBedroom(bedroomType)
								listing[:baths] = reformatBathroom(bathroomType)
								listing[:unit] = listingDetail["apartmentNumber"]
								listing[:price] = listingDetail["pricing"]["effectiveRent"]
								#Fill in details based on its community code (standard data for different building)
								listing[:images] = Array.new
								listing[:images] << { origin_url: floorplanImg1 }
								retrieve_listing_basics(listingDetail, listing)
								listing[:url] = @urlCove
								check_title listing

								if block_given?
									@logger.info listing
									yield(listing)
								else
									p listing
								end

								countingIndex = countingIndex + 1 
							end
						end
					end
				end
			end
		end
	end
end
