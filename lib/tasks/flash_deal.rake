namespace :set do
  desc "Setting certain set of TFC apartments to be constantly featured"
  task flash_sale: :environment do

    #ADDED MANAGEMENTS
    #TFCornerstone, Rose Associates, StuyTown, Glenwood, LaLezarian
    #


    #Companies like Rose Associates and TFC via brokerage name query
    #TFC
    contact_brokerage = ["TF Cornerstone, Inc.","Milford Management"]

    contact_brokerage.each do |brokerage|
      all_listings = Broker.find_by(name: brokerage).listings
      all_listings.each do |listing|
        if listing.status == 0
          listing.update(is_flash_sale: true)
        end
        if listing.status == 1
          listing.update(is_flash_sale: false)
        end
      end
    end

    contact_brokerage_2 = ["Bold New York"]
    contact_brokerage_2.each do |brokerage|
      all_listings = Broker.find_by(name: brokerage).listings
      all_listings = all_listings.where("street_address like ? AND status like ?", "605 W 42nd Street", 0)
      all_listings.each do |listing|
        if listing.status == 0
          listing.update(is_flash_sale: true)
        end
        if listing.status == 1
          listing.update(is_flash_sale: false)
        end
      end
    end

    #More customization on TFC
    tfc_agent_exception = Agent.find_by(name: "Robert Schmidt").listings
    tfc_agent_exception.each do |listing|
      if listing.status == 0
        listing.update(is_flash_sale: true)
      end
      if listing.status == 1
        listing.update(is_flash_sale: false)
      end
    end

    #Removing Jose Estevez westside apartments
    tfc_agent_exception = Agent.find_by(name: "Jose Estevez").listings
    tfc_agent_exception.each do |listing|
      listing.update(is_flash_sale: false)
    end

    #Glenwood, Rockrose, LaLezarian
    contact_names = ["Rockrose Development Corp", "Lalezarian Properties", "Glenwood Realty", "Newport Rental Towers", "Forest City", "TwoTree Management", "ManhattanPark"]

    contact_names.each do |name|
      listings = Listing.where("contact_name like ? AND status like ?", name, 0)
      listings.each do |listing|
        if listing.status == 0
          listing.update(is_flash_sale: true)
        end
        if listing.status == 1
          listing.update(is_flash_sale: false)
        end
      end
    end

    #Stuytown, ONLY 1 BED AND 2 BED HAVE OP
    listings = Listing.where(contact_name: "StuyTown Apartments").where(status: 0)
    listings_one = listings.where(beds: 1)
    listings_two = listings.where(beds: 2)
    listings_one.each do |listing|
      if listing.status == 0
        listing.update(is_flash_sale: true)
      end
      if listing.status == 1
        listing.update(is_flash_sale: false)
      end
    end
    listings_two.each do |listing|
      if listing.status == 0
        listing.update(is_flash_sale: true)
      end
      if listing.status == 1
        listing.update(is_flash_sale: false)
      end
    end

    #general check
    general_listings = Listing.where(is_flash_sale: true).where(status: 1)
    general_listings.each do |set_false|
      set_false.update(is_flash_sale: false)
    end
  end
end
