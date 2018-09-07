class MlsInfo < ActiveRecord::Base
  belongs_to :listing
  belongs_to :broker
  def self.get_mls_info_id_from_xmlhash(hash)
    if hash.brokerage_name.present?
      broker_tmp = Broker.get_broker_from_hash(hash)
    else
      broker_tmp = Hashie::Mash.new
    end
    mls = where(name: hash.mls_name, mls_id: hash.mls_id, broker_id: broker_tmp.id).first_or_create
    mls.listing_id = hash.listing_id
    mls.broker_name ||= broker_tmp.short_name || hash.broker_name
    mls.save
    mls
  end
  def self.fix_mls_listing_address
    lls = Listing.where(id: select(:listing_id).to_a).where(political_area_id: nil)
    lls.each do |l|
      if l.formatted_address.present?
        l.update_columns formatted_address: nil if l.formatted_address !~ /^\d/
      end
      l.city_name = 'new york'
      l.status = 0
      l.save
    end
  end
end
