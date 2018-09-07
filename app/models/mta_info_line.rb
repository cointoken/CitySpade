class MtaInfoLine < ActiveRecord::Base
  has_many :mta_info_sts, dependent: :destroy
  has_many :listing_mta_lines, dependent: :destroy
  has_many :building_mta_lines, dependent: :destroy
  scope :buses, -> { where(mta_info_type: 'bus') }
  scope :subways, -> { where(mta_info_type: 'subway') }
  def icon_url
    origin_url = read_attribute(:icon_url)
    if origin_url && self.location == 'nyc'
      l = origin_url.split('/').last.split('.').first
      "icons/lines/sub#{l}.png"
    elsif self.location == 'philadelphia'
      url = "icons/lines/philadelphia/#{self.name.to_url}.png"
      if File.exist? Rails.root.join('app/assets/images', url)
        url
      else
        'icons/lines/philadelphia/regional-rail.png'
      end
    elsif self.location == 'boston'
      'icons/lines/boston/' + self.name.split(/\s/).map(&:first).join + '.png'
    else
      "icons/lines/" + self.location.downcase + '/' + self.name.to_url + '.png'
    end
  end

  class << self
    def nyc_lines
      @nyc_lines ||= where(location: 'nyc')
    end
    def nyc_line_ids
      nyc_lines.map(&:id)
    end
    def philadelphia_lines
      @philadelphia_lines ||= where(location: 'philadelphia')
    end
    def philadelphia_line_ids
      philadelphia_lines.map(&:id)
    end
    def refresh
      MapsServices::MTAInfo.setup
    end
  end
end
