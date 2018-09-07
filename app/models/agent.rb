class Agent < ActiveRecord::Base
  belongs_to :broker
  belongs_to :account
  has_many :listings
  has_many :agent_languages, dependent: :destroy
  has_many :languages, through: :agent_languages
  #has_many :photos, class_name: Photo::Agent, as: :imageable, dependent: :destroy
  mount_uploader :photo, AgentUploader

  validates_presence_of :name, :email, :tel, :address
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: ->(agent){ agent.email.present? }


  #before_destroy :cancel_rel_listings
  #before_save :check_tel, if: ->(agent) {agent.changed.include?('tel')}
  #before_save :check_agent, if: ->(agent) { ['tel', 'name'].any?{|col| agent.changed.include?(col)} }

  #include FogS3

  #extend FriendlyId
  #friendly_id :address, use: :slugged

  def to_param
    "#{id}-#{name}".to_url
  end

  def cancel_rel_listings
    listings.update_all agent_id: nil
  end

  def self.get_from_realty_mx(agent)
    find_and_update_from_hash({
      email: agent.email_address,
      origin_url: agent.picture_url,
      name: "#{agent.first_name} #{agent.last_name}",
      tel: (agent.office_line_number || agent.mobile_phone_line_number || '').gsub(/\D/, '')
    })
  end

  def self.save_from_mls(agent, listing, opt={mls_id: nil})
    broker = nil
    broker_id = listing.broker_id
    mls_info_id = listing.mls_info_id
    if agent.broker_name && broker_id.blank?
      broker = Broker.where(name: agent.broker_name).first_or_initialize
      broker.update_attributes(street_address: agent.address)
      broker_id = broker.id
    end
    if mls_info_id.blank? && opt[:mls_id] && broker
      mls_info = MlsInfo.where(listing_id: listing.id, mls_id: opt[:mls_id], broker_name: broker.short_name, broker_id: broker.id, name: opt[:mls_name]).first_or_create
      mls_info_id = mls_info.id
    end
    obj = Agent.find_and_update_from_hash({name: agent.name, email: agent.email})
    obj.avatar_url ||= agent.avatar_url
    obj.tel  ||= agent.tel
    # obj.address ||= agent.address
    obj.broker_id ||= broker_id
    obj.save
    listing.update_columns broker_id: broker_id, mls_info_id: mls_info_id, agent_id: obj.id
  end

  def avatar_url(size = '60X75')
    if self.account
      if self.photos.first
        self.photos.first.image.send("v_#{size.sub('x', 'X')}").url
      end
    else
      if self.url(size)
        self.url(size)
      else
        'icons/agent_avatar.jpg'
      end
    end
  end

  def img_alt
    [self.name, self.broker.try(:name)].join(", ")
  end

  def about_title
    if introduction.present?
      "About Me"
    elsif broker.try(:introduction).present?
      "About #{broker.name || 'Me'}"
    else
      nil
    end
  end

  def remark
    introduction || broker.try(:introduction)
  end

  def full_broker_name
    broker.try :name
  end
  def can_link?
    avatar_url && email && tel.present?
  end

  def check_agent
    check_tel if changed.include?('tel')
    check_name if changed.include?('name')
  end

  def check_tel
    agt_tel = self.tel
    if agt_tel.present?
      agt_tel = agt_tel.split(/[A-z]/)[0].gsub(/\D+/, "")
      agt_tel = agt_tel[-10..-1] if (agt_tel.size == 11 && agt_tel[0] == "1") or (agt_tel.size == 13 && agt_tel[0..2] == "001")
      agt_tel = agt_tel[0..9] if agt_tel.size > 11
      agt_tel = nil if agt_tel.size < 9
    end
    self.tel = agt_tel
  end

  def check_name
    if self.name.size > 26
      nm = self.name.split(/make/i).first
      self.name = nm if nm.size > 6
    end
  end

  def self.fix_agents_tel
    self.all.each do |agent|
      if agent.tel.present?
        agt_tel = agent.tel.split(/[A-z]/)[0].gsub(/\D+/, "")
        agt_tel = agt_tel[-10..-1] if (agt_tel.size == 11 && agt_tel[0] == "1") or (agt_tel.size == 13 && agt_tel[0..2] == "001")
        agt_tel = agt_tel[0..9] if agt_tel.size > 11
        agt_tel = nil if agt_tel.size < 9
        agent.update_column(:tel, agt_tel)
      end
    end
  end

  def self.fix_agents_name
    where('length(name) > 26').each do |agent|
      agent.check_name
      agent.save
    end
  end

  def self.delete_repeat_agents
    agent_columns = Agent.column_names.reject{|s| [:id, :name, :created_at, :updated_at, :listing_num].include? s.to_sym}
    #ll_ids = []
    self.where(broker_id: nil).to_a.group_by{|s| s.name.to_s + s.email.to_s}.each do |_, ags|
      ag = Agent.where("broker_id IS NOT NULL").where(name: ags.first.name, website: ags.first.website).first
      ag.present? ? other_ags = ags : (ag, other_ags = ags[0], ags[1..-1])
      lls = Listing.where(agent_id: other_ags.map(&:id))
      if ag.broker_id.blank?
        broker_id = lls.where("broker_id IS NOT NULL").first.try(:broker_id)
        ag.update_column(:broker_id, broker_id) if broker_id.present?
      end
      lls.update_all agent_id: ag.id, broker_id: ag.broker_id
      agent_columns.each do |col|
        ag.send "#{col}=", other_ags.select{|s| s.send(col).present?}.first.try(col) if ag.send(col).blank?
      end
      ag.save
      other_ags.each(&:destroy)
    end
  end

  def self.find_and_update_from_hash hash, full_match_flag = false
    opt = hash.slice(:broker_id, :broker).reject{|_, v| v.blank?}
    if full_match_flag
      agent = Agent.where(hash).first
    else
      if hash[:email]
        opt[:email] = hash[:email].strip
        agent = where(opt).first
      end
      if !agent && hash[:website].present?
        #hostname = URI(hash[:website]).hostname
        #hostname = hash[:website] if hostname.blank?
        agent = where(opt).where('website like ?', "#{hash[:website].strip.remove(/\/$/)}%").first
      end
      agent ||= where(opt).where(name: hash[:name].strip).first if hash[:name].present?
    end
    agent ||= Agent.create(hash)
    agent.update_attributes hash if agent.updated_at && agent.updated_at < Time.now - 2.day || ['email', 'tel', 'origin_url'].any?{|attr| agent.send(attr).blank? && hash[attr.to_sym]}
    agent
  end

  def self.fix_name_and_email
    Agent.all.each do |ag|
      ag.update_column(:email, nil) if ag.name == ag.email
    end
  end

  def self.default_sizes
    Settings.image_sizes['Agent']
  end
end
