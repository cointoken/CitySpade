module Spider
  module Chicago
    class ChicagoBozzuto < Spider::Chicago::Base
    	def initialize(accept_cookie: true)
    		
        #
        @oneelevenURL = "https://twenty20cambridge.securecafe.com/onlineleasing/twenty20/oleapplication.aspx?stepname=Apartments&myOlePropertyId=449362"
        @oneelevenEncoded = URI.encode(@oneelevenURL)
        @oneelevenURI = URI.parse(@oneelevenEncoded)
        @docOneeleven = Nokogiri::HTML(open(@oneelevenURI))

        @securecafeFormat = [@docOneeleven]
        @buildingPage = ["http://www.bozzuto.com/apartments/communities/847-oneeleven"]
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

        listing[:description] = "The sleek grandeur of OneEleven’s architecture continues into every apartment home we offer. Meticulously selected finishes and exquisitely designed layouts create a truly remarkable living experience. This isn’t just any apartment in Chicago. This is THE Chicago apartment you want."
        listing[:amenities] = []
        #listing[:amenities] <<
        #puts (buildingDocDetails.css(".row.feature").css("#li_cont2")).length
        listing[:contact_name] = "Bozzuto Management"


        listing[:title] = "111 West Wacker Drive"
        listing[:city_name] = "Chicago"
        listing[:state_name] = "IL"
        listing[:zipcode] = "60601"
        listing
      end

      # 0 - CapitolChelsea, 1 - Observer
      def retrieveAgents(index, listing)
        case index
        when 0
          listing[:contact_tel] = "8669794852"
          listing[:email] = "tobrien@bozzuto.com"
          listing[:url] = @oneelevenEncoded
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