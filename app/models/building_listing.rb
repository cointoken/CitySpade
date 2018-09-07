class BuildingListing < ActiveRecord::Base
  belongs_to :listing
  belongs_to :building
  BOROUGHS = {'Manhattan' => 'MN', 'Brooklyn' => 'BK', 'Queens' => 'QN', 'Bronx' => 'BX', 'Staten Island' => 'SI'}
  def self.binding_building listing
    if listing.is_full_address && listing.formatted_address.present? && listing.political_area
      #lls = Listing.where(formatted_address: listing.formatted_address).where("id in (select listing_id from building_listings)").first
      lls = BuildingListing.where(listing: Listing.where(formatted_address: listing.formatted_address)).first.try(:listing)
      l_building = nil
      if lls.present?
        l_building = lls.building
      elsif listing.city.try(:long_name) == 'New York' #&& listing.geo && listing.geo.success?
        l_building = Building.where(address: listing.geo_street_address, borough: BOROUGHS[listing.political_area.borough.try('long_name')], city: 'NYC').first ||
          AddressTranslator.find_building_from_address_translator(listing.geo_street_address, borough: BOROUGHS[listing.political_area.borough.try('long_name')], city: 'NYC') ||
          Building.where(address: listing.geo_street_address, borough: BOROUGHS[listing.political_area.borough.try('long_name')], city: 'NYC').create
      end
      if l_building
        listing.building_listing ||= listing.build_building_listing
        listing.building_listing.update_attributes building: l_building
      else
        BuildingListing.where(listing: listing).destroy_all
      end
    end
  end

  def self.update_same_formatted_address
    BuildingListing.group(:building_id).pluck(:building_id).each do |building_id|
      l_building = Building.find building_id
      l = l_building.listings.last.first
      if l && l.formatted_address.present?
        lls = Listing.where(formatted_address: l.formatted_address).where.not(id: l_building.listings.pluck(:id))
        lls.each do |ll|
          binding_building ll
        end
      end
    end
  end
end
