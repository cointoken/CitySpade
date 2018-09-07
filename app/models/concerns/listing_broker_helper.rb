module ListingBrokerHelper

  MLS_BROKER = %w{ maxwellrealty bushari centrerealtygroup livecharlesgate}
  def can_find_tel_by_brokers?
    contact_tel.present?
  end
  alias_method :can_find_tel?, :can_find_tel_by_brokers?

  def is_mls?
    self.mls_info_id.present? || MLS_BROKER.include?(broker_site_name)
  end
  def contact_tel
    ## for mls
    if read_attribute(:contact_tel) && read_attribute(:contact_tel).size == 10
      return read_attribute(:contact_tel)
    end
    if self.agent
      self.agent.tel || self.agent.broker.try(:tel)
    elsif self.broker
      self.broker.tel
    else
      if MLS_BROKER.include?(self.broker_site_name) && self.read_attribute(:contact_name) != 'Maxwell Realty Company'
        Broker.tel_by_broker_info(self.get_broker_info, self.id)# || read_attribute(:contact_tel)
      else
        read_attribute(:contact_tel)
      end
    end
  end

  def broker_name
    if broker_name_from_url
      broker_name_from_url
    elsif self.broker_id
      self.broker.name
    else
      read_attribute(:broker_name) 
    end
  end

  def broker_name_from_url
    nil
    #if self.broker_site_name == 'aptsandlofts'
    #'Apt And Loft'
    #end
  end

  def url_from_broker
    case broker_name
    when 'StuyTown Apartments'
      'http://www.pcvstliving.com/cityspade'
    end
  end

  def agent_img_alt
    if self.agent
      [self.agent.name, broker_name].uniq.join(', ')
    else
      [contact_name, broker_name].uniq.join(', ')
    end
  end

  def agent_name
    if agent
      agent.name
    elsif read_attribute(:contact_name) && broker_name
      unless read_attribute(:contact_name).downcase.include?(broker_name.downcase)
        read_attribute(:contact_name)
      end
    end
  end

  def contact_name
    if self.mls_info_id.present? && read_attribute(:contact_name)
      return read_attribute(:contact_name)
    end
    if MLS_BROKER.include?(broker_site_name)
      if broker_name && agent_name && !can_find_tel_by_brokers?
        "#{agent_name}, #{broker_name}"
      else
        read_attribute(:contact_name)
      end
    else
      agent_name || read_attribute(:contact_name)
    end
  end

  def get_broker_info
    tmp_name = broker_name || contact_name
    tmp_name.gsub!(/(\,\s+)?(llc|inc)\.+?$/i, '')
    tmp_name.gsub!(/\.+$/, '')
    tmps = tmp_name.split(',').map(&:strip)
    if tmps.size > 1
      [tmps[1], tmps[0]]
    else
      tmps = tmps.first.split(' of ')
      if tmps.size > 1
        [tmps[1..-1].join(' of ').split(/\||\-/).first.strip, tmps.first]
      else
        tmps
      end
    end
  end

  BROKER_ICON_URLS =  Dir[Rails.root.join('app','assets', 'images', 'icons/brokers', '*').to_path].map do |img|
    File.basename(img).split('.').first
  end

  def broker_icon_url
    if broker_site_name
      if BROKER_ICON_URLS.include?(broker_site_name)
        if self.broker_site_name == 'lefrak' && self.political_area.try(:long_name) == 'Newport'
          "icons/brokers/newportrentalsnj.jpg"
        else
          "icons/brokers/#{broker_site_name}.jpg"
        end
      else
        if self.state.try(:short_name) == 'MA'
          'icons/brokers/boston.jpg'
        else
          "icons/brokers/default.jpg"
        end
      end
    else
      "icons/brokers/default.jpg"
    end
  end

  def broker_site_name
    @broker_site_name ||= begin
                            tmp_url = self.origin_url || self.broker.try(:website)
                            if tmp_url.present?
                              site = URI(tmp_url).hostname
                              if site
                                sites = site.split('.')
                                sites[-2]
                              end
                            elsif self.listing_provider
                              self.listing_provider.client_name.downcase
                            end
                          end
  end

  def self.included(base)
    base.extend ListingBrokerHelper::ClassMethods
  end

  module ClassMethods
    def update_broker_info
      MLS_BROKER.each do |mls|
        listings = Listing.enables.where('created_at > ? and origin_url like ?', Time.now - 3.day, "%#{mls}%").order('id desc')
        listings.map(&:contact_tel)
      end
    end
  end
end
