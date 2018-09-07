class BrokerLlsStatus < ActiveRecord::Base
  def self.update_datas(day = Date.today, target = nil)

    ## for realtymx
    if target.nil? || target == 'RealtyMx'
      broker_ids = Listing.realtymx.distinct(:broker_id).pluck(:broker_id).compact
      broker_ids.each do |id|
        broker = Broker.find_by_id id
        next unless broker
        update_for_query Listing.realtymx.where(broker: broker),day,name: broker.name, mls_name: 'realtymx', status_date: day
      end
    end
    if target.nil? || target == 'Rentlinx'
      broker_ids = Listing.rentlinx.distinct(:broker_id).pluck(:broker_id).compact
      broker_ids.each do |id|
        broker = Broker.find_by_id id
        next unless broker
        update_for_query Listing.rentlinx.where(broker: broker),day, name: broker.name, mls_name: 'rentlinx', status_date: day
      end
    end
    return unless target.nil?
    Listing.all_sites.each do |name|
      lls = Listing.try(name.underscore) || Listing.try(name.remove(/\-|\_/).underscore)
      update_for_query lls,day, name: name, status_date: day
    end
  end

  def self.update_for_query lls, day, opts = {}
    @@mn_ids ||= PoliticalArea.nyc.sub_areas.where(long_name: 'manhattan').map{|s| s.sub_ids(include_self: true)}.flatten
    @@bk_ids ||= PoliticalArea.nyc.sub_areas.where(long_name: 'Brooklyn').map{|s| s.sub_ids(include_self: true)}.flatten
    @@qn_ids ||= PoliticalArea.nyc.sub_areas.where(long_name: 'Queens').map{|s| s.sub_ids(include_self: true)}.flatten
    @@bn_ids ||= PoliticalArea.nyc.sub_areas.where(long_name: 'Bronx').map{|s| s.sub_ids(include_self: true)}.flatten
    active_lls = lls.enables.size
    added_today = lls.where('created_at like ?', "%#{day}%").size
    expired_today = lls.expired.where('updated_at like ?', "%#{day}%").size
    manhattan = lls.enables.where(political_area_id: @@mn_ids).size
    brooklyn = lls.enables.where(political_area_id: @@bk_ids).size
    queens = lls.enables.where(political_area_id: @@qn_ids).size
    bronx = lls.enables.where(political_area_id: @@bn_ids).size
    other_cities = lls.enables.where.not(political_area_id: PoliticalArea.nyc.sub_ids).size
    active_no_fee = lls.enables.where(no_fee: true).size
    added_no_fee = lls.enables.where(no_fee: true).where('created_at like ?', "%#{day}%").size
    expired_no_fee = lls.expired.where(no_fee: true).where('created_at like ?', "%#{day}%").size

    b_lls = self.where(opts).first_or_initialize
    if b_lls.new_record?
      b_lls.update_attributes(active_lls: active_lls, added_today: added_today, expired_today: expired_today,
                              manhattan: manhattan, brooklyn: brooklyn, queens: queens, bronx: bronx, other_cities: other_cities,
                              active_no_fee: active_no_fee, added_no_fee: added_no_fee, expired_no_fee: expired_no_fee)
    else
      b_lls.update_columns({active_lls: active_lls, added_today: added_today, expired_today: expired_today,
                            manhattan: manhattan, brooklyn: brooklyn, queens: queens, bronx: bronx, other_cities: other_cities,
                            active_no_fee: active_no_fee, added_no_fee: added_no_fee, expired_no_fee: expired_no_fee})
    end

  end
end
