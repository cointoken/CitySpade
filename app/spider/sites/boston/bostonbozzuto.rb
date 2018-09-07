module Spider
  module Boston
    class BostonBozzuto < Spider::Boston::Base
    	def initialize(accept_cookie: true)
    		#Boston Apartments

        #Chinatown Boston
        @oneGreenwayURL = "https://onegreenwayboston.securecafe.com/onlineleasing/one-greenway/oleapplication.aspx?stepname=Apartments&myOlePropertyId=449361"
        @oneGreenwayURI = URI.parse(@oneGreenwayURL)
        @theKensingtonURL = "https://kensingtonboston.securecafe.com/onlineleasing/the-kensington/oleapplication.aspx?stepname=Apartments&myOlePropertyId=226817"
        @theKensingtonURI = URI.parse(@theKensingtonURL)

        #Seaport District
        @parklaneURL = "https://parklaneseaport.securecafe.com/onlineleasing/park-lane-seaport/oleapplication.aspx?stepname=Apartments&myOlePropertyId=214079"
        @parklaneURI = URI.parse(@parklaneURL)
        @watersideURL = "https://watersideboston.securecafe.com/onlineleasing/waterside-place/oleapplication.aspx?stepname=Apartments&myOlePropertyId=214086"
        @watersideURI = URI.parse(@watersideURL)
        @flatsondURL = "https://flatsond.securecafe.com/onlineleasing/flats-on-d/oleapplication.aspx?stepname=Apartments&myOlePropertyId=240743"
        @flatsondURI = URI.parse(@flatsondURL)

        #Cambridge 
        @twentyURL = "https://twenty20cambridge.securecafe.com/onlineleasing/twenty20/oleapplication.aspx?stepname=Apartments&myOlePropertyId=449362"
        @twentyURI = URI.parse(@twentyURL)

        @docOneGreenway = Nokogiri::HTML(open(@oneGreenwayURI))
        @docTheKensington = Nokogiri::HTML(open(@theKensingtonURI))
        @docParkLane = Nokogiri::HTML(open(@parklaneURI))
        @docWaterside = Nokogiri::HTML(open(@watersideURI))
        @docFlatsond = Nokogiri::HTML(open(@flatsondURI))
        @docTwenty = Nokogiri::HTML(open(@twentyURI))
        @securecafeFormat = [@docOneGreenway,@docTheKensington,@docParkLane,@docWaterside,@docFlatsond,@docTwenty]
        @buildingPage = ["https://www.bozzuto.com/apartments/communities/353-one-greenway","https://www.bozzuto.com/apartments/communities/275-the-kensington","https://www.bozzuto.com/apartments/communities/224-park-lane-seaport","https://www.bozzuto.com/apartments/communities/300-waterside-place","https://www.bozzuto.com/apartments/communities/374-flats-on-d","https://www.bozzuto.com/apartments/communities/846-twenty20"]
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
        contact_txt = contactText.css('p')[1].try(:text)

        if !contact_txt.nil? && contact_txt.include?("Boston")
          matchText = (/Boston, /).match(contact_txt)
          #Save one match text as string to enable string manipulations
          matchTextString = matchText.to_s
          listing[:title] = (matchText.pre_match).to_s #Street Address, but the matching part is like "New York, "
          listing[:city_name] = ((/, /).match(matchTextString).pre_match).to_s
          listing[:state_name] = (((/ /).match((matchText.post_match).to_s)).pre_match).to_s
          listing[:zipcode] = (((/ /).match((matchText.post_match).to_s)).post_match).to_s
        end
        if !contact_txt.nil? && contact_txt.include?("Cambridge")
          matchText = (/Cambridge, /).match(contact_txt)
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
          listing[:contact_tel] = "8887742859"
          listing[:email] = "kwalker@bozzuto.com"
          listing[:url] = @oneGreenwayURL
        when 1
          listing[:contact_tel] = "8884488930"
          listing[:email] = "dpereira@bozzuto.com"
          listing[:url] = @theKensingtonURL
        when 2
        	listing[:contact_tel] = "8886248651"
        	listing[:email] = "ragostino@bozzuto.com"
        	listing[:url] = @parklaneURL
        when 3
          listing[:contact_tel] = "8885624944"
          listing[:email] = "kwalker@bozzuto.com"
          listing[:url] = @watersideURL
        when 4
          listing[:contact_tel] = "8884092875"
          listing[:email] = "akekeisen@bozzuto.com"
          listing[:url] = @flatsondURL
        when 5 
          listing[:contact_tel] = "8887836550"
          listing[:email] = "cfantone@bozzuto.com"
          listing[:url] = @twentyURL
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
