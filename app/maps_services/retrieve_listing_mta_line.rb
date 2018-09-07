module MapsServices
  class RetrieveListingMtaLine
    def self.setup(opt={})
      if opt.class.to_s == 'Listing'
        listings = [opt]
      elsif opt.is_a? Array
        listings = opt
      else
        limit = opt[:limit] || 1000
        listings = Listing.enables.where('place_flag < 3 or (place_flag != 7 and place_flag > 3)').limit(limit)
        listings = listings.where(political_area_id: PoliticalArea.all_city_sub_area_ids)
      end
      listings.each_with_index do |listing, index|
        sts = listing.stations_near_by('subway_station')[0..10] + listing.stations_near_by('bus_station')[0..10]
#        ActiveRecord::Base.transaction do
          sts.each do |st|
            type = st.target.split('_').first
            line = ListingMtaLine.find_or_create_by(listing: listing, mta_info_line: st.mta_info_line, target: type)
            line.update_attribute(:mta_info_st, st) if line.mta_info_st.blank?
          end
          # listing.update_place_flag(2)
          listing.cal_place_flag([1,2])
          listing.update_column(:place_flag, listing.place_flag + 3)
        listing.cal_distance_for_mta_line
        end
        # sleep(rand)
#      end
      ListingMtaLine.cal_distances
    end

    def self.fix_old_lines(opts = {limit: 3000})
      listing = Listing.enables.includes(:listing_mta_lines).references(:listing_mta_lines).order(:id).
        where('listing_place_id is not null and listing_mta_lines.mta_info_st_id is null').last
      listings = Listing.enables.includes(:listing_mta_lines).references(:listing_mta_lines).
        where('listing_place_id is not null and listing_mta_lines.mta_info_st_id is null').
        where("listings.id <= ?", listing.id).order('listings.id desc').limit(opts[:limit])
      setup listings.to_a
    end

    def self.fix_lost_subway_lines
      listings = Listing.enables.where('created_at > ?', Time.now - 7.day)
      results = []
      listings.each do |listing|
        if [3, 7].include? listing.place_flag
          unless listing.subway_lines.present?
            results << listing
          end
        end
      end
      setup results
    end

    def self.resetup(opt={})
      #listings = Listing.enables.where(place_flag: [2, 3, 6, 7]).where(opt)
      #listings.each do |listing|
      #lines = listing.listing_mta_lines.where(target: 'subway')
      #lines.each do |line|
      #unless line.listing_place.get_mta_st.map{|s| s.mta_info_line_id}.include? line.mta_info_line_id
      #line.destroy
      #end
      #end
      #places = listing.places.st_places.where(target: 'subway')
      #places.each do |pl|
      #sts = pl.get_mta_st
      #type = pl.target.split('_').first
      #if sts.present?
      #sts.each do |st|
      #line = ListingMtaLine.find_or_create_by(listing: listing, mta_info_line: st.mta_info_line, target: type)
      #line.update_attribute(:listing_place, pl) if line.listing_place.blank?
      #end
      #end
      #end
      #listing.cal_distance_for_mta_line
      #end
    end
  end
end
