class TransportDistance < ActiveRecord::Base
  belongs_to :listing
  belongs_to :transport_place
  default_scope -> { includes(:transport_place).references(:transport_place) }
  delegate :name, to: :transport_place
  #  def duration
  #read_attribute(:duration) + 2 * 60 
  #end
  def cal_duration
    read_attribute(:cal_duration) || duration
  end

  def self.fix_transport_distances(opt = {})
    cal_ids = []
    Listing.where('id > 136000 and id < 141000 and place_flag = 7').where(opt[:query]).limit(opt[:limit]).order(id: :desc).each do |l|
      same_listings = l.same_addresses.where(place_flag: 7).order(id: :asc)
      if same_listings.any?{|s| s.transport_distances.blank?} || l.transport_distances.blank?
        same_listings.each{|s| s.cancel_cal}
        l.cancel_cal
        next
      end
      if same_listings.size > 0 && !cal_ids.include?(l.id)
        if same_listings.any?{|s| (s.transport_distances.first.duration - l.transport_distances.first.duration).abs > 60}
          l_min = same_listings.first
          same_listings.each do |s|
            if s.id > l_min.id 
              if (s.transport_distances.first.duration - l_min.transport_distances.first.duration).abs < 10
                l_min = s
              end
            end
          end
          l.cancel_cal
          cal_ids << l.id
          same_listings.each do |s|
            cal_ids << s.id
            s.cancel_cal if s.id != l_min.id
          end
          l.save
          same_listings.each{|s| s.save}
          arr = same_listings.to_a << l
          MapsServices::TransportScore.setup arr
        end
      end
    end
  end
end
