class Broker < ActiveRecord::Base
  has_many :listings
  has_many :agents, dependent: :destroy
  has_many :mls_infos

  validates_uniqueness_of :name, scope: [:website, :state, :status]
  validates_presence_of :name

  enum status: [:enable, :disable]

  default_scope ->{ enable }

  serialize :tel

  before_save :decorator_tel
  before_destroy :cancel_rel_listings

  def cancel_rel_listings
    listings.update_all broker_id: nil
  end
  def decorator_tel
    name = name.remove(/\.+$/) if name.present?
    if self.tel.present?
      return if tel.is_a?(Array)
      if self.tel.include?('/')
        self.tel = self.tel.split('/').map{|t| t.gsub(/\D/, '')}
      else
        self.tel = self.tel.gsub(/\D/, '')
      end
    end
  end

  def self.find_and_update_from_hash hash
    if hash[:email]
      if hash[:state].present?
        broker = Broker.find_by_email_and_state hash[:email].strip, hash[:state].strip
      end
      broker ||= Broker.find_by_email hash[:email]
    end
    broker ||= Broker.find_by_website hash[:website] if hash[:website]
    broker ||= Broker.where(hash.slice(:name, :state)).first
    unless broker
      broker = Broker.create! hash
    end
    broker.update_attributes hash if broker.updated_at < Time.now - 2.day
    broker
  end

  def self.find_by_website site
    if site.present?
      hostname = URI(site).hostname
      hostname = site if hostname.blank?
      where('website like ?', "%#{hostname}%").first
    end
  rescue
    where(website: site).first
  end

  def name
    nm = read_attribute(:name)
    if nm
      if nm.size < 6
        nm.downcase =~ /^(none|llc|ltd|corp|inc|resis|llp)/ ? 'Not Specified' : nm
      else
        nm
      end
    end
  end

  def self.load_info_from_seeds
    seed_path = Rails.root.join('db', 'db_seeds.yml')
    if File.exist? seed_path
      yml = YAML::load_file seed_path
      yml[:brokers].each do |broker|
        bk = where(name: broker[:name].strip).first_or_initialize
        bk.tel = broker[:tel]
        bk.email = broker[:email]
        bk.save
      end
    end
  end

  def self.tel_by_name(name)
    broker = where(name: name.strip).first
    if broker && broker.tel.present?
      if broker.tel.is_a?(String)
        broker.tel
      else
        broker.tel.try :first
      end
    else
      nil
    end
  end

  def self.tel_by_broker_info(info, listing_id = nil)
    broker = where(name: info.first).first || where('name like ?', "#{info.first}%").first
    if broker && broker.tel.present?
      BrokerUpdateWorker.perform_async(broker.id, info, listing_id)
      if broker.tel.is_a?(String)
        broker.tel
      else
        broker.tel.try :first
      end
    else
      nil
    end
  end

  def self.get_broker_from_hash(obj)
    obj.brokerage_name = obj.office_name if obj.brokerage_name.blank?
    hash = {
      website: obj.broker_website, email: obj.broker_email, tel: obj.broker_phone,
      street_address: obj.street_address, state: obj.state, client_id: obj.client_id,
      name: obj.brokerage_name
    }
    find_and_update_from_hash hash
  end

  def short_name
    if website.present?
      www = website.split('.')[-3]
      if www && www != 'www' && !www.include?('/')
        www
      else
        website.split('.')[-2]
      end
    else
      name.to_url
    end
  end

  def get_listing_num(flag = false)
    if flag
      self.update_columns listing_num: Listing.where(broker_id: self.id).count
    else
      self.listing_num
    end
  end

  def self.reset_listing_num
    Broker.all.each do |broker|
      broker.get_listing_num true
    end
    Agent.all.each do |agent|
      agent.update_columns listing_num: agent.listings.count
    end
  end

  def self.reload_brokers
    Listing.enables.where(contact_tel: nil, broker_id: nil).where('broker_name is not null').each do |l|
      bk = where(name: l.broker_name.strip).first_or_initialize
      bk.listing_num ||= 0
      bk.listing_num += 1
      bk.save
      l.update_column :broker_id, bk.id
    end
  end

  def self.find_broker_by_name(name, state_name = nil)
    opt = {name: name.remove(/\.+$/)}
    opt[:state] = state_name if state_name
    where(opt)
  end

  def self.reset_states
    Broker.where(state: nil).each do |broker|
      listings = Listing.where("broker_id = ? or agent_id in (#{(broker.agents.map(&:id) << -1).join(',')})", broker.id)
      states = listings.map{|s| [s.state_name, s.id, s.agent_id]}.group_by{|s| s[0]}.map{|k,s| [k, s, s.size]}.sort{|x, y| y[2] <=> x[2]}
      if states.size == 1
        broker.update_columns state: states[0][0]
      elsif states.size > 1
        broker.update_columns state: states[0][0]
        agents   = Agent.where("broker_id = ? or id in (#{(listings.pluck(:agent_id).uniq.compact << -1).join(',')})", broker.id)
        states.delete_at 0
        states.each do |st|
          br = where(name: broker.name, website: broker.website, state: st[0]).first || broker.dup
          br.state = st[0]
          br.tel = nil if br.new_record?
          br.save
          listings.where(id: st[1].map{|s| s[1]}).update_all broker_id: br.id
          agents.where(id: st[1].map{|s| s[1]}).update_all broker_id: br.id
        end
      end
    end
  end

  def delete_repeat_agents
    agent_columns = Agent.column_names.reject{|s| [:id, :name, :created_at, :updated_at, :listing_num].include? s.to_sym}
    self.agents.to_a.group_by{|s| s.name}.each do |_, ags|
      if ags.size > 1
        other_ags = ags[1..-1]
        ag        = ags[0]
        lls = Listing.where(agent_id: other_ags.map(&:id))
        lls.update_all agent_id: ag.id, broker_id: self.id
        agent_columns.each do |col|
          ag.send "#{col}=", other_ags.select{|s| s.send(col).present?}.first.try(col) if ag.send(col).blank?
        end
        ag.save
        other_ags.each(&:destroy)
      end
    end
  end

  def self.delete_repeat_broker
    broker_columns = Broker.column_names.reject{|s| [:id, :name, :created_at, :updated_at, :listing_num].include? s.to_sym}
    all.pluck(:id).each do |b_id|
      broker = Broker.unscoped.enable.find_by_id b_id
      if broker
        others = Broker.where(state: broker.state)
        if broker.website.present?
          others = others.where('name = ? and website like ?', broker.name.strip, "#{broker.website.strip.remove(/\/$/)}%")
        else
          others = others.where(name: broker.name.strip)
        end
        others = others.where.not(id: b_id)
        if others.present?
          others.each do |other|
            other.agents.update_all broker_id: b_id
          end
          Listing.where(broker: others).update_all broker_id: b_id
        end
        broker_columns.each do |col|
          broker.send "#{col}=", others.select{|s| s.send(col).present?}.first.try(col) if broker.send(col).blank?
        end
        others.each(&:disable!)
        broker.save
        broker.delete_repeat_agents
        Listing.where(agent: broker.agents).update_all broker_id: b_id
      end
    end
    Agent.delete_repeat_agents
  end

  def added_listings
    self.listings.where("created_at > ?", Time.zone.now.beginning_of_day)
  end

  def expired_listings
    self.listings.expired.where("updated_at > ?", Time.zone.now.beginning_of_day)
  end

  def no_fee_listings
    self.listings.where(no_fee: true)
  end

  def added_no_fee_listings(date=Time.zone.now)
    date = Time.zone.now if date.blank?
    self.listings.where(no_fee: true).where(["created_at >= ? AND created_at <= ?", date.to_date.beginning_of_day, date.to_date.end_of_day])
  end

  def expired_no_fee_listings(date=Time.zone.now.beginning_of_day)
    date = Time.zone.now if date.blank?
    self.listings.expired.where(no_fee: true).where(["updated_at >= ? AND updated_at <= ?", date.to_date.beginning_of_day, date.to_date.end_of_day])
  end
end
