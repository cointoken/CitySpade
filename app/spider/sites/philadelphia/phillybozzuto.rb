module Spider
  module Philadelphia
    class PhillyBozzuto < Spider::Philadelphia::Base
    	def initialize
    		#Center City Area
        @edgeWaterURL = "https://edgewaterapthomes.securecafe.com/onlineleasing/edgewater-apartments-1/oleapplication.aspx?stepname=Apartments&myOlePropertyId=214088"
        @edgeWaterURI = URI.parse(@edgeWaterURL)
        @thePepperURL = "https://thepepperbuilding.securecafe.com/onlineleasing/the-pepper-building/oleapplication.aspx?stepname=Apartments&myOlePropertyId=207918"
        @thePepperURI = URI.parse(@thePepperURL)
        @locustURL = "https://1500locustapartments.securecafe.com/onlineleasing/1500-locust/oleapplication.aspx?stepname=Apartments&myOlePropertyId=340664"
        @locustURI = URI.parse(@locustURL)
        @chestnutURL = "https://3737chestnut.securecafe.com/onlineleasing/3737-chestnut/oleapplication.aspx?stepname=Apartments&myOlePropertyId=389527"
        @chestnutURI = URI.parse(@chestnutURL)

        @docEdgeWater = Nokogiri::HTML(open(@edgeWaterURI))
        @docThePepper = Nokogiri::HTML(open(@thePepperURI))
        @docLocust = Nokogiri::HTML(open(@locustURI))
        @docChestnut = Nokogiri::HTML(open(@chestnutURI))
        @securecafeFormat = [@docEdgeWater,@docThePepper,@docLocust,@docChestnut]
        @buildingPage = ["https://www.bozzuto.com/apartments/communities/30-edgewater-apartments","https://www.bozzuto.com/apartments/communities/246-the-pepper-building","https://www.bozzuto.com/apartments/communities/238-1500-locust","https://www.bozzuto.com/apartments/communities/688-3737-chestnut"]
      end

      def pullingListingAddress(buildingURL, listing)
        buildingDocContact = Nokogiri::HTML(open(URI.parse(buildingURL + "/contact")))
        buildingDocDetails = Nokogiri::HTML(open(URI.parse(buildingURL + "/features")))
        buildingDocImages = Nokogiri::HTML(open(URI.parse(buildingURL + "/media")))
        #REMEMBER TO ADD BROOKLYN INTO THIS!!!!!
        contactText = buildingDocContact.css("#community-contact-text")
        #contactText.css("p")[1].text
        #puts buildingDocImages.css(".slides").css("img").length
        #puts buildingDocImages.css(".slides").css("img")
        listing[:images] = []
        countInt = 0 #used for image count
        while (countInt < (buildingDocImages.css(".slides").css("img").length)/2) do #too many photos so i cut in half
          listing[:images] << { origin_url: buildingDocImages.css(".slides").css("img")[countInt]["src"] }
          countInt = countInt + 1
        end
        #retrieve_images(buildingDocImages, listing)
        #puts contactText.css("p")[2].text
        #puts buildingDocContact.css(".phone-number")
        if listing[:description] = buildingDocDetails.css(".row.feature").css("p").css("span")[0] != nil
          listing[:description] = buildingDocDetails.css(".row.feature").css("p").css("span")[0].text
        end
        listing[:amenities] = []
        #listing[:amenities] <<
        #puts (buildingDocDetails.css(".row.feature").css("#li_cont2")).length
        listing[:contact_name] = "Bozzuto Management"

        if contactText.css("p")[1].text.include?("Philadelphia")
          matchText = (/Philadelphia, /).match(contactText.css("p")[1].text)
          #Save one match text as string to enable string manipulations
          matchTextString = matchText.to_s
          listing[:title] = (matchText.pre_match).to_s #Street Address, but the matching part is like "New York, "
          listing[:city_name] = ((/, /).match(matchTextString).pre_match).to_s
          listing[:state_name] = (((/ /).match((matchText.post_match).to_s)).pre_match).to_s
          listing[:zipcode] = (((/ /).match((matchText.post_match).to_s)).post_match).to_s
        end
        listing
      end

      # 0 - CapitolChelsea, 1 - Observer
      def retrieveAgents(index, listing)
        case index
        when 0
          listing[:contact_tel] = "8887181654"
          listing[:email] = "nfontaine@bozzuto.com"
          listing[:url] = "https://edgewaterapthomes.securecafe.com/onlineleasing/edgewater-apartments-1/oleapplication.aspx?stepname=Apartments&myOlePropertyId=214088"
        when 1
          listing[:contact_tel] = "8773573311"
          listing[:email] = "kgrant@bozzuto.com"
          listing[:url] = "https://thepepperbuilding.securecafe.com/onlineleasing/the-pepper-building/oleapplication.aspx?stepname=Apartments&myOlePropertyId=207918"
        when 2
        	listing[:contact_tel] = "8884818450"
        	listing[:email] = "dmcmurtrie@bozzuto.com"
        	listing[:url] = "https://1500locustapartments.securecafe.com/onlineleasing/1500-locust/oleapplication.aspx?stepname=Apartments&myOlePropertyId=340664"
          listing[:title] = "1500 Locust Street"
          listing[:city_name] = "Philadelphia"
          listing[:state_name] = "PA"
          listing[:zipcode] = "19102"
        when 3
          listing[:contact_tel] = "8886256480"
          listing[:email] = "3737chestnut@bozzuto.com"
          listing[:url] = @chestnutURL
          listing[:title] = "3737 Chestnut Street"
          listing[:city_name] = "Philadelphia"
          listing[:state_name] = "PA"
          listing[:zipcode] = "19104"
        end
        listing
      end

      def listings(options={})
        index = 0
        @securecafeFormat.each do |extractListing|
          floorPlanTypeDoc = extractListing.css("#hideMap > .row-fluid")
          loopLength = floorPlanTypeDoc.length
          indexTracker = 0
          floorPlanTypeDoc.each do |innerLoop|
            #indexTracker = 0
            if extractListing.at_css("#other-floorplans")
              while (indexTracker < (loopLength - 1)) do
                textDoc = floorPlanTypeDoc[indexTracker].at_css("#other-floorplans")
                #Pull Bedroom and Bathroom Numbers
                if textDoc != nil
                  bedMatch = (/ Bedroom/).match(textDoc.text)
                  bathMatch = (/ Bathroom/).match(textDoc.text)
                  bedroom = (bedMatch.pre_match)[bedMatch.pre_match.length - 1]
                  bathroom = (bathMatch.pre_match)[bathMatch.pre_match.length - 1]
                end
                indexTracker = indexTracker + 1
                unitDoc = (floorPlanTypeDoc[indexTracker]).css(".AvailUnitRow")
                #This starts to pull listings
                unitDoc.each do |listingPulling|
                  #price needs special handling
                  priceRange = priceRange = listingPulling.css("td")[2].text
                  priceRange = priceRange.delete("$,")
                  matchTextNew = (/-/).match(priceRange)
                  if (matchTextNew != nil)
                    price = (matchTextNew.pre_match).to_i
                  else 
                    price = priceRange
                  end
                  
                  listing = {}
                  listing[:flag] = 1
                  listing[:no_fee] = true #Bozzuto is a property management
                  listing[:is_full_address] = true
                  listing[:beds] = bedroom
                  listing[:baths] = bathroom
                  listing[:unit] = listingPulling.css("td")[0].text.delete("#")
                  
                  listing[:price] = price
                  pullingListingAddress(@buildingPage[index],listing)
                  retrieveAgents(index, listing)

                  next unless listing
                  check_title listing

                  if block_given?
                    #@logger.info listing
                    yield(listing)
                  else
                    listing
                  end
                  #next unless listing
                  #check_title listing
                end
              end
            end
          end
          index += 1
        end
      end    
    end
  end
end
