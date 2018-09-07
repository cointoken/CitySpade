module Spider
  def self.run(clses = nil, city_cls = nil)
    classes = clses || %w{
      Halstead Corcoran
      Elliman Kwnyc NestSeekers
      Mns CitiHabitats Townrealestate
    }
    [*classes].each do |cls|
      if city_cls
        cls = Spider.const_get(city_cls).const_get(cls)
      else
        cls = Spider::Sites::Base.descendants.select{|c| c.to_s.include?(cls)}.first
      end
      next unless cls
      Spider.setup(image: true, class: cls)
      Spider.improve_listings(cls)
    end
  end

  def  self.setup(options={image: false, doexpired: false, test_flag: false})
    begin
      kclasses = []
      if options[:class].present?
        kclasses << options[:class]
      else
        kclasses = []#Spider::Base.descendants
      end
      title = "Spider for: #{kclasses}"
      spider_res = {new_num: 0, update_num: 0}
      current_class = nil
      kclasses.each do |kclass|
        current_class = kclass.to_s.split('::').last
        spider = kclass.new
        options[:check_listing] = spider.check_listing
        lls = spider.listings(options) do |listing|
          sync_listing listing, spider_res, options
          break if options[:test_flag]
        end
        ## set expired
        if options[:doexpired] && (kclass.respond_to?(:enable_urls) || (Hash === lls && lls[:url].present?))
          lls_method = kclass.to_s.split("::").last.underscore
          urls = kclass.try(:enable_urls) || lls[:url]
          Spider::ImproveListing.expired_for_exclude_url(lls_method, urls.flatten.uniq)
        end
        RecordStorage.spider flag: :error, target: current_class, method: :set
      end
      if !options[:doexpired] && !options[:test_flag]
        Listing.improve_addresses
        Listing.cal_score_prices
      end
    rescue => err
      message = [err.message, err.backtrace.inspect].flatten.join("\n")
      p err.backtrace
      title << "(error)"
      RecordStorage.spider flag: :error, target: current_class, method: :set, val: true if current_class
    ensure
      message ||= "#{kclasses} finished"
      message << "\n update: #{spider_res[:update_num]}\n new: #{spider_res[:new_num]}\n\n"
      p message
      send_mail title, message
    end
  end

  def self.transit(opt = {})
    return if Time.now.month == 9 && Time.now.day == 26
    begin
      title = "RetrieveListingMtaLine"
      #MapsServices::Place.setup opt
      MapsServices::RetrieveListingMtaLine.setup opt
    rescue => err
      title << "(error)"
      message = [err.message, err.backtrace.inspect].join("\n")
    ensure
      message ||= "finished"
      send_mail title, message
      # SystemMailer.notice(title, message).deliver
    end
  end
  def self.cal_transit_score(opt={limit: 200})
    return if Time.now.month == 9 && Time.now.day == 26
    begin
      title = "cal transport score"
      MapsServices::CalTransportDistance.setup opt
    rescue => err
      message = [err.message, err.backtrace.inspect].join("\n")
    ensure
      message ||= "finished"
      send_mail title, message
      # SystemMailer.notice(title, message).deliver
    end
  end

  def self.improve_listings(target = nil)
    begin
      title = "improve listings"
      Spider::ImproveListing.setup target
    rescue => err
      message = [err.message, err.backtrace.inspect].join("\n")
    ensure
      message ||= "finished"
      send_mail title, message
      # SystemMailer.notice(title, message).deliver
    end
  end
  def self.send_mail(title, message)
    SystemMailer.notice(title, message).deliver unless Rails.env.development?
  end

  def self.feeds_setup(mls_classes)
    mls_classes.split(',').each do |mls_class|
      mls_class.strip!
      begin
        title = "Spider (#{mls_class})"
        Spider::Feeds.const_get(mls_class).setup
      rescue => err
        message = [err.message, err.backtrace.inspect].join("\n")
      ensure
        message ||= "finished"
        send_mail title, message
        # SystemMailer.notice(title, message).deliver
      end
    end
  end

  def self.setup_nyc_no_fee opt= {}
    default_opt = {image: true, doexpired: true, return_attrs: :url, listing: {no_fee: true, is_full_address: true, status: 0}}
    default_opt = default_opt.merge opt
    Dir[Rails.root.join('app/spider/sites/nyc', 'no_fee_*.rb')].each do |path|
      site = File.split(path).last.remove(/^no\_fee\_|\.rb/).capitalize
      if site !~ /\d/ && site !~ /pistilli/
        kclass = "Spider::NYC::#{site}"
        next unless Object.const_defined?(kclass)
        kclass = kclass.constantize
        setup default_opt.merge(class: kclass)
      end
    end
  end

  def self.sync_listing(listing, spider_res = {}, options = {})
    return unless listing
    if listing[:lat].present?
      return if listing[:lat].to_i == 0 || listing[:lng].to_i == 0
    end

    ## set listing default value
    if options[:listing] && Hash === options[:listing]
      options[:listing].each do |key, value|
        if listing[key].blank?
          listing[key] = value
        end
      end
    end
    listing[:price] = listing[:price].to_f
    images = listing.delete(:images)
    return unless listing[:url]
    listing[:raw_neighborhood] ||= listing.delete :neighborhood_name
    listing[:url].strip!
    listing[:status] ||= 0
    broker = listing.delete :broker
    agents = listing.delete :agents
    object = Listing.get_listing_from_spider(listing)
    #          ActiveRecord::Base.transaction do
    if object
      return unless object.is_accessible?
      unless object.update_attributes(listing)
        Rails.logger.info object.errors.full_messages
        return
      end
      spider_res[:update_num] += 1
    else
      unless listing[:status] == 1
        object = Listing.new listing
        unless object.save
          Rails.logger.info object.errors.full_messages
          return
        end
        spider_res[:new_num] += 1
      end
    end

    if object.present?
      if broker.present?
        broker[:state] ||= listing[:state_name] if listing[:state_name]
        #if broker[:website].present? || (broker[:name] && broker[:state])
        #if broker[:website]
        #_broker = Broker.find_by_website broker[:website]
        #end
        #_broker ||= Broker.where(broker.slice(:state, :name)).first_or_initialize
        #_broker.update_attributes! broker
        #else
        #_broker = Broker.create! broker
        #end
        _broker = Broker.find_and_update_from_hash broker
        object.update_columns broker_id: _broker.id if object.broker_id.blank?
        if agents.present? && !_broker.new_record?
          agents = agents.map{|_agent|
            next if _agent[:website].blank? && _agent[:email].blank?
            #agent.update_attributes _agent.merge(broker_id: _broker.id)
            _broker.agents.find_and_update_from_hash _agent
          }
          if object.agent_id.blank?
            object.update_columns agent_id: agents.first.try(:id) if agents.first
          end
        end
      end
      if listing[:broker_name]
        unless object.broker
          object.update_columns broker_id: Broker.find_broker_by_name(listing[:broker_name], listing[:state_name]).first_or_create.id
        end
        if object.broker && listing[:contact_name] && !object.agent_id && listing[:contact_name] != listing[:broker_name] && listing[:contact_name].downcase != 'none'
          agent = object.broker.agents.find_and_update_from_hash({name: listing[:contact_name]})
          object.update_columns agent_id: agent.id if agent
        end
      end
      return unless object && !object.new_record? && options[:image]
      return unless object.is_enable?
      if options[:check_listing].present?
        options[:check_listing].each do |key, call|
          unless call.call(object[key])
            object.update_columns status: 4
            break
          end
        end
      end
      # next if object.listing_images.present?
      (images || [])[0...10].each do |image|
        image[:origin_url] = image[:origin_url].remove(/\?(\d|\-)+$/)
        ListingImage.where(origin_url: image[:origin_url], listing_id: object.id).first_or_create
      end
    end
  end

  def self.fix_broker_datas
    brokers = Broker.unscoped.where('name like ?', '% of %')
    brokers.each do |broker|
      broker.tel = broker.tel.try(:first) unless String === broker.tel
      names = broker.name.split(' of ')
      agent_name = names.first.strip
      broker_name = names[1..-1].join(' of ').strip
      obj = Broker.find_broker_by_name(broker_name).first_or_initialize
      obj.update_attributes(
        street_address: broker.street_address,
        website: broker.website,
        zipcode: broker.zipcode,
        client_id: broker.client_id,
        introduction: broker.introduction
      )
      broker.agents.update_all broker_id: obj.id
      agent = obj.agents.find_and_update_from_hash({name: agent_name})
      agent.update_attributes tel: broker.tel, email: broker.email
      broker.listings.update_all broker_id: obj.id, agent_id: agent.id, contact_name: agent.name, contact_tel: agent.tel
      broker.disable!
    end
    brokers = Broker.unscoped.where('name like ?', '%,%')
    brokers.each do |broker|
      broker.tel = broker.tel.try(:first) unless String === broker.tel
      names = broker.name.split(',')
      next if names.size == 2 && names.last.strip.size < 15
      agent_name = names.first.strip
      broker_name = names[1..-1].join(',').strip
      obj = Broker.find_broker_by_name(broker_name).first_or_initialize
      obj.update_attributes(
        street_address: broker.street_address,
        website: broker.website,
        zipcode: broker.zipcode,
        client_id: broker.client_id,
        introduction: broker.introduction
      )
      broker.agents.update_all broker_id: obj.id
      agent = obj.agents.find_and_update_from_hash({agent: agent_name})
      agent.update_attributes tel: broker.tel, email: broker.email
      broker.listings.update_all broker_id: obj.id, agent_id: agent.id, contact_name: agent.name, contact_tel: agent.tel
      broker.disable!
    end
  end

  def self.sync_expired_for_old_listings opt={}
    Listing.enables.where('updated_at < ?', Time.now - 15.day).where(opt).limit(6000).pluck(:id).each do |arr|
      listing = Listing.find(arr)
      if listing.is_enable?
        listing.sync_expired_status
      end
    end
  end
end
