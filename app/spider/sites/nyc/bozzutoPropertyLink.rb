require 'open-uri'
require 'net/http'
require 'openssl'

#Because there are three formats for Bozzuto's properties
#It's easier to separate them, easier to debug and maintain for the future

module Spider
  module NYC
    class PropertyLink < Spider::NYC::Base
      def initialize
        @sagamoreURL = "http://www.propertylinkonline.com/Availability/Availability.aspx?c=100155&p=93393&r=0"
        sagamoreURI = URI.parse(@sagamoreURL)

        @theChelseaURL = "http://www.propertylinkonline.com/Availability/Availability.aspx?c=100155&p=93392&r=0"
        theChelseaURI = URI.parse(@theChelseaURL)

        @artisanURL = "http://www.propertylinkonline.com/Availability/Availability.aspx?c=100155&p=106656&r=0"
        artisanURI = URI.parse(@artisanURL)


        # NEW YORK CITY
        docSagamore = Nokogiri::HTML(open(sagamoreURI))
        docTheChelsea = Nokogiri::HTML(open(theChelseaURI))

        #HOBOKEN NJ
        docArtisan = Nokogiri::HTML(open(artisanURI))

        #Main Retrieve Listings
        @propertyLinkFormat = [docSagamore,docTheChelsea,docArtisan]
        @buildingPage = ["http://www.bozzuto.com/apartments/communities/242-the-sagamore","http://www.bozzuto.com/apartments/communities/245-the-chelsea","http://www.bozzuto.com/apartments/communities/421-artisan-series"]
      end

      #Pulling Basic Info for Buildings
      #Images, Location, Descriptions
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

        if contactText.css("p")[1].text.include?("New York")
          matchText = (/New York, /).match(contactText.css("p")[1].text)
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

      #Index is arranged in order, 0 - Sagamore, 1 - theChelsea, 2 - artisan (Hoboken)
      def retrieveAgents(index,listing)
        case index
        when 0  #Sagamore
          listing[:contact_tel] = "8773622684"
          listing[:email] = "cjjohnson@bozzuto.com"

        when 1 #theChelsea
          listing[:contact_tel] = "8884595280"
          listing[:email] = "jsanmiguel@bozzuto.com"

        when 2 #Artisan
          listing[:contact_tel] = "8887168573"
          listing[:email] = "dmcnally@bozzuto.com"
        end
        listing
      end

      def retrieveListingURL(index, listing)
        case index
        when 0 #Sagamore
          listing[:url] = @sagamoreURL
        when 1 #theChelsea
          listing[:url] = @theChelseaURL
        when 2 #Artisan
          listing[:url] = @artisanURL
        end
        listing
      end

      def listings(options={})
        index = 0
        @propertyLinkFormat.each do |extractListing|
          #Index for internal use
          j = 0
          while(j < extractListing.css(".floorplan").length) do
            smallerDoc = extractListing.css("#ctl00_templateBody_ltvFloorplans_ctrl#{j}_trUnits")
            if smallerDoc.at_css("tbody")
              listingRelated = smallerDoc.at_css("tbody").css(".unit")
              listingRelated.each do |extractEachListing|
                listing = {}
                listing[:flag] = 1
                listing[:no_fee] = true #Bozzuto is a property management
                listing[:is_full_address] = true
                listing[:unit] = extractEachListing.css("td")[1].text #Apartment Unit No.
                listing[:price] = (extractEachListing.css("td")[4].text.delete('$,')[1..-1]).to_i
                listing[:beds] = (extractEachListing.css("td")[2].text[0]).to_f
                listing[:baths] = (extractEachListing.css("td")[2].text[4]).to_f
                #Getting more building details
                pullingListingAddress(@buildingPage[index],listing)
                listing[:contact_name] = "Bozzuto Management"
                retrieveAgents(index,listing)
                retrieveListingURL(index, listing)

                next unless listing
                check_title listing

                if block_given?
                  #@logger.info listing
                  yield(listing)
                else
                  listing
                end
              end
              #check_title listing
              #p listing
            end
            j += 1
          end
          index += 1 #Switch to the next building
        end
      end

    end
  end
end
