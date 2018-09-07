require 'rubygems'
require 'json'
require 'pp'
require 'net/http'
require 'openssl'
require 'nokogiri'

module Spider
	module NYC
		class AvalonBay < Spider::NYC::Base
			def initialize
				super
				url = "http://api.avalonbay.com/json/reply/CommunitySearch?state=NY&area=782"
				uri = URI.parse(url)
				data = Net::HTTP.get(uri)
				@doc = JSON.parse(data)
				@avalonPropertyUrl = "http://api.avalonbay.com/json/reply/ApartmentSearch?communityCode=" #without an ending

				#urlCove = "http://api.avalonbay.com/json/reply/ApartmentSearch?communityCode=NJ002"
				#uriCove = URI.parse(urlCove)
				#dataCove = Net::HTTP.get(uriCove)
				#@docCove = JSON.parse(dataCove)
				#Cove is just a specific building, not like the NYC community in general above.
			end

			def reformatBedroom(bedroomType)
    		firstDigit = bedroomType[0].to_f # unless bedroomType.nil?
				firstDigit
			end

			def reformatBathroom(bathroomType)
			    firstDigit = bathroomType[0].to_f
			    firstDigit
			end

			#Decide the building specs using each community code
			def retrieve_listing_basics(listingDetail, listing)
				case listingDetail["communityCode"]
				when "NY026"
					listing[:title] = "343 Gold Street"
					listing[:city_name] = "Brooklyn"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11201"
					listing[:contact_tel] = "7185963143"
					listing[:description] = "Avalon Fort Greene brings new meaning to luxury with these unbeatable Brooklyn apartments built on fabulous green living principles. The massive Fort Greene Avalon Tower offers spaciously designed studios along with one-, two- and three-bedroom designs that boast spectacular views of Manhattan and Brooklyn while providing residents a high-quality living experience. Inside the homes you’ll find a wide range of amenities including spacious floor plans, vaulted ceiling, mini blinds, stainless steel sinks, linen closets, high ceilings, large closets and balconies or patios. Residents are also privy to community amenities like a state of the art fitness center, stylish resident lounge, urban park plaza and valet parking service. Adding to the list of enticing features is the fact that our Brooklyn apartments have a courteous and attentive staff as well as all the necessary amenities to cater to the most discerning New York residents."
					listing[:amenities] = ["In-unit washer/dryer","24-hour emergency maintenance","Resident clubhouse","On-site ZipCar","Ceramic tile flooring","ENERGY STAR appliances","Marble vanity"]

				when "DV007"
					listing[:title] = "214 Duffield Street"
					listing[:city_name] = "Brooklyn"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11201"
					listing[:contact_tel] = "7185963143"
					listing[:description] = ""
					listing[:amenities] = ""

				when "DV102"
					listing[:title] = "240 East Shore Road"
					listing[:city_name] = "Great Neck"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11023"
					listing[:contact_tel] = "7185963143"
					listing[:description] = ""
					listing[:amenities] = ""

				when "NY011"
					listing[:title] = "2-01 50th Avenue"
					listing[:city_name] = "Long Island City"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11101"
					listing[:contact_tel] = "7187297800"
					listing[:description] = "In the heart of Long Island City, the stunning Avalon Riverview North is an urban paradise entrenched near the East River, LaGuardia Airport and Grand Central Station. Our apartments in Long Island City offer spacious studios and one-, two- or three-bedroom floor plans to fit your needs. These stunning Long Island City apartments feature gourmet kitchens with granite countertops, washer and dryers, modern hardwood floors, maple cabinetry and so much more. The community has a host of amenities as well, including a 24-hour concierge, state of the art fitness center, 9th floor sparkling swimming pool with views of Manhattan and a roof-garden with barbecue grills are just a few of the amenities at your disposal."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Spectacular views of Manhattan skyline","WiFi access in common areas","Fully-equipped kitchens include dishwashers","10 minutes to Grand Central on 7 train","Beautifully landscaped courtyards"]

				when "NY034"
					listing[:title] = "525 West 28th Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10001"
					listing[:contact_tel] = "2122391323"
					listing[:description] = "AVA is a first. Our apartments are energized by this great city, personalized by you. You're on the High Line - steps away from the high life of art galleries, eclectic dining, and exciting clubs and bars such as the Frying Pan. Yep. Take our DIY kits and go to town in your new West Chelsea apartment. Our brand new studio, 1- and 2-bedroom apartments feature stainless steel appliances, black quartz countertops, plank flooring, and built-in charging stations.We're also smoke free, eco-friendly,and pet-friendly (big dogs too). Work out in our awesome fitness center, take in city views on the 14th floor roof deck or attend social events exclusive to AVA friends. Dive in and make it yours."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Chill Lounge","WiFi access in common areas","Fully-equipped kitchens include dishwashers","Smoke-free community","Affordable housing available"]

				when "NY018"
					listing[:title] = "4-75 48th Avenue"
					listing[:city_name] = "Long Island City"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11109"
					listing[:contact_tel] = "7189371390"
					listing[:description] = "In the heart of Long Island City, the stunning Avalon Riverview North is an urban paradise entrenched near the East River, LaGuardia Airport and Grand Central Station. Our apartments in Long Island City offer spacious studios and one-, two- or three-bedroom floor plans to fit your needs. These stunning Long Island City apartments feature gourmet kitchens with granite countertops, washer and dryers, modern hardwood floors, maple cabinetry and so much more. The community has a host of amenities as well, including a 24-hour concierge, state of the art fitness center, 9th floor sparkling swimming pool with views of Manhattan and a roof-garden with barbecue grills are just a few of the amenities at your disposal."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Spectacular views of Manhattan skyline","WiFi access in common areas","Fully-equipped kitchens include dishwashers","10 minutes to Grand Central on 7 train","Beautifully landscaped courtyards"]

				when "NY034"
					listing[:title] = "525 West 28th Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10001"
					listing[:contact_tel] = "2122391323"
					listing[:description] = "AVA is a first. Our apartments are energized by this great city, personalized by you. You're on the High Line - steps away from the high life of art galleries, eclectic dining, and exciting clubs and bars such as the Frying Pan. Yep. Take our DIY kits and go to town in your new West Chelsea apartment. Our brand new studio, 1- and 2-bedroom apartments feature stainless steel appliances, black quartz countertops, plank flooring, and built-in charging stations.We're also smoke free, eco-friendly,and pet-friendly (big dogs too). Work out in our awesome fitness center, take in city views on the 14th floor roof deck or attend social events exclusive to AVA friends. Dive in and make it yours."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Chill Lounge","WiFi access in common areas","Fully-equipped kitchens include dishwashers","Smoke-free community","Affordable housing available"]

				when "NY015"
					listing[:title] = "11 East First Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10003"
					listing[:contact_tel] = "2123877720"
					listing[:description] = "Avalon Bowery Place was designed to let you indulge in Manhattan living, the way you always dreamt. Set in the famed Bowery, this luxury residence puts you in the center of an all-encompassing lifestyle. Our luxury New York City apartments offer studios and one- or two-bedroom designs that showcase the finest blend of sophisticated appointments. These apartments in New York have features that include fully equipped gourmet kitchens with stainless steel appliances, washers and dryers, hardwood flooring, floor to ceiling windows, spacious walk-in closets and private terraces and balconies. Residents of our New York apartments have a long list of stellar community amenities at their disposal as well. These include unbeatable features such as garage parking, a landscaped courtyard, a sundeck with gas barbecue grill, views of both downtown and uptown Manhattan, a resident lounge, amazing on-site retail shops and a state of the art fitness center are all here at the apartments in New York City."
					listing[:amenities] = ["Granite countertops","Private balcony or patio","Chill Lounge","WiFi access in common areas","Fully-equipped kitchens include dishwashers","Smoke-free community","Garages and covered parking"]

				when "NY533"
					listing[:title] = "515 West 52nd Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10019"
					listing[:contact_tel] = "2129578200"
					listing[:description] = "In the midst of the bustling city of Manhattan, you will discover the serenity of world class living at Avalon Clinton. Stumble upon thoughtfully designed studio, one-, and two-bedroom New York apartment rentals that will cater to all your needs. All our homes are equipped with luxurious amenities like floor-to-ceiling windows, parquet wood flooring, spacious closets, and white-on-white appliances. The Avalon Clinton apartment community offers breathtaking views of the Manhattan skyline as well as a wealth of facilities such as two private health clubs, cat-friendly homes, roof-top sky decks, and laundry rooms. The brilliant array of features and a courteous on-site staff makes this Avalon community the ideal place to set up your new home."
					listing[:amenities] = ["Granite countertops","24-hour concierge","On-site retail and restaurants","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]

				when "NYC40"
					listing[:title] = "377 East 33rd Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10016"
					listing[:contact_tel] = "2126841333"
					listing[:description] = "Enjoy beautiful views of the East River and the Chrysler building from your stunning apartment homes at Avalon Kips Bay. Discover studio, one-, two-, three- and four-bedroom New York apartment rentals that surpass all expectations in terms of their quality and design. Each of our lovely homes is equipped with amazing features such as granite countertops, stainless steel appliances, European-style marble vanities and high-speed internet access. You'll also enjoy excellent facilities within our Avalon community like an on-site fitness center with cardio theater equipment, additional storage and parking. The great collection of amenities and a professional on-site staff makes Avalon Kips Bay the ideal place to set up your new home."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Ceramic tile flooring","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]

				when "NY525"
					listing[:title] = "250 West 50th Street"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10019"
					listing[:contact_tel] = "2122455050"
					listing[:description] = "Discover life in the Big Apple with beautiful studio, one- and two-bedroom New York apartments at Avalon Midtown West. Enjoy a wide array of world class features such as open architecture featuring angled walls, high ceilings and wall-to-wall windows that provide sweeping city views, modern appliances, breakfast bars and white cabinetry, parquet wood flooring, and Botticino marble hotel-style vanities in the bathrooms. The Midtown West community also provides various facilities for residents like a fitness Center featuring cardio theatre equipment, resistance machines, free weights and a sauna, a wireless lounge fitted with convenient laptop tables, complimentary WiFi service and plasma TV, laundry facilities, Thalia Restaurant and the Food Emporium located on site on the ground level, and an expansive community room with multiple seating groups, plasma TV, laptop tables and caterers kitchen. The excellent amenities and professional on-site staff make this New York community the ideal place to live."
					listing[:amenities] = ["Granite countertops","24-hour concierge","On site ATM","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]


				when "NY023"
					listing[:title] = "1 Morningside Drive"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10025"
					listing[:contact_tel] = "2123160529"
					listing[:description] = "Wake up every day next to the stunning Morningside and Central Parks right in the heart of Manhattan at Avalon Morningside Park. Our brand new high-rise apartments in New York City, on Manhattan's Upper West Side, offer spacious studios and one-, two- and three-bedroom options each boasting breathtaking views of the New York City skyline, East River, the parks and the rest of the sights of the city that never sleeps. The apartments in New York City sport luxury amenities like gourmet kitchens equipped with beautiful granite countertops and stainless steel appliances, spacious bathrooms with marble vanities, walk-in closets, floor to ceiling windows, washers and dryers in each home and beautiful hardwood floors. Residents can also enjoy a host of spectacular features like a state of the art fitness center with cardio theater, yoga room, children’s playroom, game room, resident lounge, landscaped courtyards and the easy access to the nearby parks’ biking and jogging trails."
					listing[:amenities] = ["Granite countertops","24-hour concierge","ENERGY STAR appliances","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]

				when "NY029"
					listing[:title] = "282 11th Avenue"
					listing[:city_name] = "New York"
					listing[:state_name] = "NY"
					listing[:zipcode] = "10001"
					listing[:contact_tel] = "2125642813"
					listing[:description] = "We believe elevating where you live is about blending it seamlessly with how you live. We go to great lengths designing amenities and choosing locations that put everything within reach. Where you live, is where you come alive. In a flourishing area, Avalon offers New York apartments that cater to all of your needs. Escape the hustle and bustle of midtown, inside our refreshing smoke-free community. Within our walls, you'll find thoughtfully designed studio, one- and two-bedroom apartment homes. Imagine entertaining in gourmet kitchens with ENERGY STAR® stainless steel appliances and quartz stone countertops. Live your life effortlessly with amenities that include a state-of-the-art fitness center, a resident lounge with a large entertaining kitchen and an outdoor lounge on the 8th floor with Hudson River and skyline views. Not to mention our community is also within walking distance to Citi Bike, C/E subway lines, Penn Station and the High Line. Make Avalon West Chelsea your next home and personal retreat within the city. This is not just apartment living. This is living up."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Central to the 7-line subway extension and the High Line","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]

				when "NY037"
					listing[:title] = "100 Willoughby Street"
					listing[:city_name] = "Brooklyn"
					listing[:state_name] = "NY"
					listing[:zipcode] = "11201"
					listing[:contact_tel] = "7186431581"
					listing[:description] = "Which is why we chose to be in the heart of it all - steps from cultural icons such as the Barclay's Center and Brooklyn Flea, and local restaurants and nightlife of Fort Greene, Carroll Gardens, and Brooklyn Heights. Our brand new studio, 1-, 2-, and 3-bedroom floor plans feature kitchens with stainless steel appliances, quartz-stone countertops, and tile backsplashes. Plus, each unit comes with hard-surface plank flooring, in-unit washer/dryer, and built-in charging station. Our community also features a 58th floor rooftop deck and lounge, 30th floor terrace with fire pit and grills, heated indoor/outdoor dog run, and fully-equipped fitness center . Best of all, we're directly above the subway giving you immediate access to the A, C, F, and R trains, and less than a 5-minute walk from the 2, 3, 4, 5, B, N, and Q trains - making your home the perfect home base."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Hard-surface plank flooring","WiFi access in common areas","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]


				when "NJ002"
					listing[:title] = "444 Washington Boulevard"
					listing[:city_name] = "Jersey City"
					listing[:state_name] = "NJ"
					listing[:zipcode] = "07310"
					listing[:contact_tel] = "2012169200"
					listing[:description] = "Located by the historic Waterfront Walkway on the Hudson River, Avalon Cove brings a new sense of luxury living to this metropolis. Our newly renovated Jersey City apartments boast one-, two-, three- and four-bedroom designs in this bustling haven. Some of the upgrades you will find include designer gourmet kitchens with granite counters, stainless-steel appliances, hardwood floors, espresso cabinetry, marble tile bathrooms, spacious walk-in closets and private patios and balconies with great views of Manhattan. Residents can choose to spend their leisure time in the landscaped barbecue and picnic areas, at the sparkling outdoor heated swimming pool, state of the art fitness center, clubroom with billiards or at the beautiful waterfront walkway. Residents can also engage in sporting activities as our Jersey City apartments have an indoor basketball court, two lighted tennis courts and two indoor racquetball courts. Residents of our apartments in Jersey City also have access to local public transportation, on-site storage units, private garage space, gated entrance with controlled access and 24-hour maintenance service."
					listing[:amenities] = ["Granite countertops","Marble tile entries and baths","Spacious walk-in closets","24-hour emergency maintenance","Fully-equipped kitchens include dishwashers","On-site laundry facilities","Complimentary package acceptance service"]

				end
				listing
			end


			def listings(options={})
			#First go through all communities in New York City and {Newport Avalon Cove}
				@doc["results"].each do |community|
					apartmentUrl = @avalonPropertyUrl + community["communityCode"]
					apartmentURI = URI.parse(apartmentUrl)
					apartmentData = Net::HTTP.get(apartmentURI)
					apartmentJSON = JSON.parse(apartmentData)
					apartmentJSON["results"]["availableFloorPlanTypes"].each do |floorPlanTypes|
						#floorplan = pullEachFloorPlan["http://resource.avalonbay.com/floorplans/NYC40/studio-531sf-21A-23A.jpg"]
						floorPlanTypes["availableFloorPlans"].each do |getDetails|
							#Bedroom Number is the same for apartments under same floorplan type
							bedroomType = getDetails["floorPlanType"]
							bathroomType = getDetails["floorPlanBathType"]
							floorplanImg1 = getDetails["floorPlanImage"]

							#Need to change some lines here since it's only pulling one listing from each ["apartments"] tag 
							#Last one is pulled now 

							apartmentBlock = getDetails["finishPackages"][0]["apartments"]
							countingIndex = 0

							while (countingIndex < apartmentBlock.length) do 
								apartmentBlock.each do |listingDetail|
									listing = {}
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

									listing[:url] = apartmentUrl

									if block_given?
										@logger.info listing
										yield(listing)
									else
										p listing
									end
									#Increment the counting for "apartment block" loop
									countingIndex = countingIndex + 1 
								end
							end
						end
					end
				end
			end
		end
	end
end
