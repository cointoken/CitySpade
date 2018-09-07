namespace :set do
  desc "Setting certain set of TFC apartments to be constantly featured"
  task temp_flash_sale: :environment do
    #Glenwood, Rockrose, LaLezarian
    contact_names = ["Forest City", "TwoTree Management"]

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

    #general check
    general_listings = Listing.where(is_flash_sale: true).where(status: 1)
    general_listings.each do |set_false|
      set_false.update(is_flash_sale: false)
    end
  end
end