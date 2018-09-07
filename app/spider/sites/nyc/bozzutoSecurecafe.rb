require 'open-uri'
require 'net/http'
require 'openssl'

module Spider
  module NYC
    class Securecafe < Spider::NYC::Base
      #Capitol Chelsea is the securecafe format
      def initialize
        @capitolChelseaURL = "https://bozzuto.securecafe.com/onlineleasing/capitol-at-chelsea/oleapplication.aspx?stepname=Apartments&myOlePropertyId=228606"
        @capitolChelseaURI = URI.parse(@capitolChelseaURL)
        #Hoboken
        @observerURL = "https://observerpark.securecafe.com/onlineleasing/observer-park/oleapplication.aspx?stepname=Apartments&myOlePropertyId=231623"
        @observerURI = URI.parse(@observerURL)
        @docCapitolChelsea = Nokogiri::HTML(open(@capitolChelseaURI))
        @docObserver = Nokogiri::HTML(open(@observerURI))
        @securecafeFormat = [@docCapitolChelsea,@docObserver]
        @buildingPage = ["http://www.bozzuto.com/apartments/communities/533-capitol-at-chelsea","http://www.bozzuto.com/apartments/communities/65-observer-park"]
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

        if contactText.css("p")[1].text.include?("New York City")
          matchText = (/New York City, /).match(contactText.css("p")[1].text)
          #Save one match text as string to enable string manipulations
          matchTextString = matchText.to_s
          listing[:title] = (matchText.pre_match).to_s #Street Address, but the matching part is like "New York, "
          listing[:city_name] = ((/, /).match(matchTextString).pre_match).to_s
          listing[:state_name] = (((/ /).match((matchText.post_match).to_s)).pre_match).to_s
          listing[:zipcode] = (((/ /).match((matchText.post_match).to_s)).post_match).to_s
        end
        if contactText.css("p")[1].text.include?("Hoboken")
          #((/Hoboken, /) === (contactText.css("p")[1].text))
          matchText = (/Hoboken, /).match(contactText.css("p")[1].text)
          #Save one match text as string to enable string manipulations
          matchTextString = (matchText.pre_match).to_s
          listing[:title] = matchText.pre_match
          listing[:raw_neighborhood] = "Hoboken"
          listing[:city_name] = "Jersey City"
          listing[:state_name] = (((/ /).match((matchText.post_match).to_s)).pre_match).to_s
          listing[:zipcode] = (((/ /).match((matchText.post_match).to_s)).post_match).to_s
        end
        if contactText.css("p")[1].text.include?("Brooklyn")
          matchText = (/Brooklyn, /).match(contactText.css("p")[1].text)
          #Save one match text as string to enable string manipulations
          matchTextString = (matchText.pre_match).to_s
          listing[:title] = matchText.pre_match
          listing[:city_name] = "Brooklyn"
          listing[:state_name] = (((/ /).match((matchText.post_match).to_s)).pre_match).to_s
          listing[:zipcode] = (((/ /).match((matchText.post_match).to_s)).post_match).to_s
        end
        listing
      end

      # 0 - CapitolChelsea, 1 - Observer
      def retrieveAgents(index, listing)
        case index
        when 0
          listing[:contact_tel] = "8774753612"
          listing[:email] = "cjjohnson@bozzuto.com"
        when 1
          listing[:contact_tel] = "8888470212"
          listing[:email] = "mgallagher@bozzuto.com"
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
                    listing = {}
                    price = (matchTextNew.pre_match).to_i
                    # listing={}
                    listing[:flag] = 1
                    listing[:no_fee] = true #Bozzuto is a property management
                    listing[:is_full_address] = true
                    listing[:beds] = bedroom
                    listing[:baths] = bathroom
                    listing[:unit] = listingPulling.css("td")[0].text.delete("#")
                    listing[:url] = index == 0 ? @capitolChelseaURL : @observerURL
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
