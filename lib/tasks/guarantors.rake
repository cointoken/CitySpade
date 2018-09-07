namespace :set do
  desc "Set guarantor field in the listings"
  task guarantor: :environment do

    buildings = ["610 W 42nd St", "620 W 42nd St", "605 W 42nd St", "650 W 42nd St", "388 Bridge St", "1510 Lexington Ave", "100 Jay St", "66 Rockwell Pl"]

    buildings.each do |building|
      list = Listing.where('formatted_address like ?',"#{building}%")
      list = list.where(flag: 1).enables
      #puts "#{building} - #{list.count}"
      list.each do |listing|
        if !listing.guarantor
          listing.update(guarantor: true)
        end
      end
    end
  end
end
