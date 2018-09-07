class ListingProvider < ActiveRecord::Base
  belongs_to :listing
  CLIENT_NAMES = ListingProvider.distinct(:client_name).pluck(:client_name).map(&:upcase)

  def self.has_client?(name)
    CLIENT_NAMES.include? name.upcase
  end

  class << self

    def update_provider(opt)
      raise 'please given a name and provider id/listing id' if opt[:client_name].blank? || opt[:provider_id].blank? || opt[:listing_id].blank?
      listing_id = opt.delete :listing_id
      pd = ListingProvider.where(opt).first_or_initialize
      pd.listing.try(:set_expired) if pd.listing_id && pd.listing_id != listing_id
      pd.listing_id = listing_id
      pd.save
    end
    def added_listings(listing_ids)
      Listing.where(id: listing_ids).where("created_at > ?", Time.zone.now.beginning_of_day)
    end

    def expired_listings(listing_ids)
      Listing.expired.where(id: listing_ids).where("updated_at > ?", Time.zone.now.beginning_of_day)
    end

    def area_listings(listing_ids, area)
      if area =~ /Other Cities/i
        a_ids = PoliticalArea.pluck(:id) - PoliticalArea.where(long_name: "New York").map{|p| p.sub_ids(include: self)}.flatten
        political_areas = PoliticalArea.where(id: a_ids)
      else
        political_areas = PoliticalArea.where(long_name: area)
      end
      area_ids = political_areas.map do |po_area|
        po_area.sub_ids(include: self)
      end.flatten.uniq
      Listing.where(id: listing_ids).where(political_area_id: area_ids)
    end

    def active_no_fee_listings(listing_ids)
      Listing.where(id: listing_ids).where(no_fee: true)
    end

    def added_no_fee_listings(listing_ids, date=Time.zone.now)
      date = Time.zone.now if date.blank?
      Listing.where(id: listing_ids).where(no_fee: true).where(["created_at >= ? AND created_at <= ?", date.to_date.beginning_of_day, date.to_date.end_of_day])
    end

    def expired_no_fee_listings(listing_ids, date=Time.zone.now)
      date = Time.zone.now if date.blank?
      Listing.expired.where(id: listing_ids).where(no_fee: true).where(["updated_at >= ? AND updated_at <= ?", date.to_date.beginning_of_day, date.to_date.end_of_day])
    end
  end

end
