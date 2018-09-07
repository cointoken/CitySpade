require 'rubygems'
require 'json'
require 'pp'
require 'net/http'
require 'openssl'
require 'nokogiri'

module Spider
	module Boston
		class AvalonBayBoston < Spider::Boston::Base
			def initialize(accept_cookie: true)
				super
				urlBoston = "http://api.avalonbay.com/json/reply/CommunitySearch?state=MA&area=1402"
				urlCambridge = "http://api.avalonbay.com/json/reply/CommunitySearch?state=MA&area=1314"
				urlSomerville = "http://api.avalonbay.com/json/reply/CommunitySearch?state=MA&area=161"
				
				uriBoston = URI.parse(urlBoston)
				dataBoston = Net::HTTP.get(uriBoston)
				@docBoston = JSON.parse(dataBoston)

				uriCambridge = URI.parse(urlCambridge)
				dataCambridge = Net::HTTP.get(uriCambridge)
				@docCambridge = JSON.parse(dataCambridge)

				uriSomerville = URI.parse(urlSomerville)
				dataSomerville = Net::HTTP.get(uriSomerville)
				@docSomerville = JSON.parse(dataSomerville)

				@areaArray = [@docBoston,@docCambridge,@docSomerville]

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
				when "MA040"
					listing[:title] = "790 Boylston Street"
					listing[:city_name] = "Boston"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02199"
					listing[:contact_tel] = "8669569735"
					listing[:description] = "AVA is a new living space in the heart of the Back Bay—where bars and shopping converge with pubs and restaurants, where sushi meets tacos, and music collides with performing arts. Oh yeah, and we're just steps from The Copley and Prudential T-Stops. From City Bar and Wired Puppy to The Pour House and Trident Booksellers and Café, there are always fun areas to explore near our Boston apartment community.

Our studio, one-, two- and three bedroom Boston apartments feature design that extends beyond your walls into social spaces to connect, relax and play. There are chill spaces with flat screens and comfy seating for hanging out with friends, free WiFi in common areas and direct access to The Shops at Prudential Center. Dive in and make it yours."
					listing[:amenities] = ["Beautiful wood flooring","Ample storage space","Energy-efficient windows","On-site ZipCar","Located near public transportation","Marble vanity"]

				when "MA044"
					listing[:title] = "45 Stuart Street"
					listing[:city_name] = "Boston"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02116"
					listing[:contact_tel] = "8665248218"
					listing[:description] = "AVA is a first. Our apartments are energized by this great city, personalized by you. Yep. Take our DIY kits and go to town in your new Theater District apartment. Steps from Boston Common, one block from the Green and Orange Lines and four blocks from the Red Line you’ll have the best of Downtown at your fingertips including entertainment, nightlife and dining. Lounge in the rooftop Sky Pavilion or attend social events exclusive to AVA friends."
					listing[:amenities] = ["Stainless steel appliances","On-site and on-call maintenance","On-site fitness center","Free Wi-Fi in all amenity areas"]

				when "MA042"
					listing[:title] = "780 Boylston Street"
					listing[:city_name] = "Boston"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02199"
					listing[:contact_tel] = "8662311272"
					listing[:description] = "Located in Boston's Back Bay, Avalon at Prudential Center offers residents an escape from the routine of everyday life. These thoughtfully designed Boston apartments make living more comfortable and luxurious in studios and one-, two- and three-bedroom designs. Our apartments in Boston are equipped with every imaginable convenience to cater to our residents every need. All homes are equipped with abundant closet space, parquet hardwood floors, spacious kitchens with granite countertops, air conditioning, private terraces and spectacular views. The community offers lots of entertainment and leisure options at our Boston apartments. Residents can spend their time at the private community room, in the courtyard, browsing through the on-site retail shopping facility, taking advantage of the valet laundry service or taking part in exclusive resident events."
					listing[:amenities] = ["Private terraces","Exclusive resident events","On-site management","Prestigious Back Bay address"]

				when "MA038"
					listing[:title] = "333 Great River Road"
					listing[:city_name] = "Somerville"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02145"
					listing[:contact_tel] = "8665877371"
					listing[:description] = "We believe upgrading where you live is about blending it effortlessly with how you live. We go to great lengths designing comforts and services along with choosing locations that put everything within reach. Where you live, is where you come alive.

Live well-appointed in Avalon at Assembly Row's brand new, smoke-free studio, one-, two-, and three-bedroom apartment homes for rent featuring walk-in closets, granite countertops, stainless steel appliances, 9-foot ceilings, and outdoor balconies. Live your life effortlessly with amenities that include a state-of-the-art fitness center, private heated outdoor pool, open air fireplace, and outdoor kitchen and barbecue areas overlooking the Mystic River. This is not just apartment living. This is living it up."
					listing[:amenities] = ["Granite countertops","24-hour concierge","Garage parking available","WiFi access in common areas","Fully-equipped kitchens include dishwashers"]

				when "MA039"
					listing[:title] = "445 Artisan Way"
					listing[:city_name] = "Somerville"
					listing[:state_name] = "MA"
					listing[:zipcode] = "10001"
					listing[:contact_tel] = "8668970059"
					listing[:description] = "AVA is a living space in Somerville ready and willing for you to BE all over the building, not just your apartment. Shopping, restaurants and entertainment are all within walking distance of our Mystic River neighborhood—or you can check out nearby Ten Hills or East Somerville. From Legal C Bar and Papagayo to Baxter State Park and AMC Theatre, you and your friends will have countless ways to socialize.

Our studios and one- and two-bedroom Somerville apartments feature an urban-inspired design with unique amenities like customizable closets and retractable walls in select floor plans. Residents can also chill out in common spaces, including a community courtyard with barbecues and a lobby loft."
					listing[:amenities] = ["Granite countertops","Urban inspired design and finishes","Chill Lounge","WiFi access in common areas","Fully-equipped kitchens include dishwashers","Smoke-free community","Keyless entry"]

				when "MA036"
					listing[:title] = "77 Exeter Street"
					listing[:city_name] = "Boston"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02116"
					listing[:contact_tel] = "8664300317"
					listing[:description] = "Boston's Back Bay, a premier location near the Charles River Basin, is the site for Avalon Exeter. These Boston apartments are a gleaming 28-story tower with brand new luxury homes that feature one-, two- and three-bedroom floor plans with panoramic views of Boston, the Charles River and Cambridge. The apartments in Boston have bright, airy designs and come with gourmet kitchens including stainless steel appliances and quartz countertops. The community amenities include a state of the art fitness center, garage parking and a 24-hour concierge and maintenance service to care for your every need. The Boston apartments also have convenient indoor access to the Prudential Center Mall and Copley Place with onsite shopping. With the vast range of amazing facilities and professional on-site management, you can see why Avalon Exeter is the best place to set up your new home."
					listing[:amenities] = ["Granite countertops","Gourmet kitchens with quartz countertops","WiFi access in common areas","Fully-equipped kitchens include dishwashers"]

				when "MAD02"
					listing[:title] = "10 Glassworks Avenue"
					listing[:city_name] = "Cambridge"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02141"
					listing[:contact_tel] = "8665487503"
					listing[:description] = "We believe elevating where you live is about blending it seamlessly with how you live. We go to great lengths designing amenities and choosing locations that put everything within reach. Where you live, is where you come alive. Avalon North Point Lofts will offer apartment homes for lease in Spring 2014. Inside our refreshing smoke-free community, you'll find thoughtfully designed loft-style studio apartments with modern finishes and designs. Imagine entertaining in contemporary living spaces with granite countertops, hard surface flooring and stainless steel appliances. Live your life effortlessly, with access to premium amenities at our adjacent sister community, Avalon North Point, including an indoor heated resort-style pool, a private theater, a sports club, internet lounge, and reserved underground parking. This is not just apartment living. This is living up."
					listing[:amenities] = ["Granite countertops","Energy-efficient fixtures","Pet-friendly community","WiFi access in common areas","24-hour emergency maintenance","Smoke-free community"]

				when "MAD01"
					listing[:title] = "1 Leighton Street"
					listing[:city_name] = "Cambridge"
					listing[:state_name] = "MA"
					listing[:zipcode] = "02141"
					listing[:contact_tel] = "8665187729"
					listing[:description] = "Discover beautiful homes at Avalon North Point that offer stunning views of Boston. You will come across stylish studio, one-, two- and three-bedroom Cambridge apartments that you can call home. Enjoy world class amenities like bamboo cabinetry, breakfast bars, designer lighting, spacious closets and kitchen islands. Residents are also privy to fantastic facilities like an indoor heated resort-style pool, a private theater, a sports club, internet lounge, and reserved underground parking. These great features and an expert on-site staff make Avalon North Point the ideal place to live."
					listing[:amenities] = ["Caesarstone countertops","Valet dry cleaning service","Chill Lounge","WiFi access in common areas","Fully-equipped kitchens include dishwashers","Smoke-free community","Underground garage parking"]
					
				end
				listing
			end

			def listings(options={})
			#First go through all communities in New York City and {Newport Avalon Cove}
				@areaArray.each do |docArea|
					docArea["results"].each do |community|
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
end
