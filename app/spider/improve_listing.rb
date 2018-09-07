module Spider
  module ImproveListing
    class << self
      def logger
        @logger ||= Spider::Logger.new
      end
      def spider
        @spider ||= Spider::Base.new(accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                                     user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36',
                                     accept_cookie: true,
                                     proxy_host: Settings.proxy_host,
                                     proxy_port: Settings.proxy_port
                                    )
      end
      def setup(target)
        if target
          target = target.to_s.downcase.split('::').last
          if target == 'citihabitats'
            target = 'citi-habitats'
          end
        end
        agents(target)
        delete_listing(redo_flag: false, query: '1', limit: 100000, target: target)
        reset_enable target
        more_info nil, target: target
        image nil, target: target
      end

      def get_site_name(listing)
        listing.broker_site_name.gsub('-', '_') if listing.broker_site_name
      end

      def reset_enable(target)
        targets = ['nestseekers', 'citi-habitats']
        return unless targets.include? target
        if Time.now.wday == 3
          listings = Listing.unscoped.latlngs.where('status != 0').where('updated_at < ? and updated_at > ?', Time.now - 3.day, Time.now - 10.day)
          listings = listings.where('origin_url like ?', "%#{target}.com%")
          delete_listing(listings.to_a)
        end
      end

      def agents(target, opt={})
        if target && Spider::Improve::Agent.respond_to?(target.gsub(/\-/, ''))
          unless Hash === opt
            agents = opt
          else
            agents = Agent.where('email is null or introduction is null or introduction = ?', '').where('website like ?', "%#{target}.com%")
          end
          agents.each do |agent|
            next if agent.website.blank?
            res = spider.get agent.website
            if res.code == '200'
              obj = {}
              doc = Nokogiri::HTML res.body
              Spider::Improve::Agent.send target.gsub(/\-/, ''), doc, obj
              if obj.present?
                agent.update_attributes obj
              end
            end
          end

        end
      end

      def expired_for_url(url)
        urls = ListingUrl.where(url: url)
        Listing.where("listing_url_id in (#{(urls.pluck(:id) << -1).join(', ')})").each do |l|
          l.set_expired
        end
      end

      def expired_for_exclude_url(target, urls)
        lls = Listing.enables
        if target
          lls = lls.try(target)
        end
        if lls.blank? && urls.present?
          domain = URI(urls.first).host
          lls = Listing.enables.where('origin_url like ?', "%#{domain}%")
        end
        if lls.present?
          lls.where.not(origin_url: urls).each(&:set_expired)
        end
      end

      def delete_listing(opt={ redo_flag: false,query: '1', limit: 500, target: nil})
        if opt.is_a? Hash
          unless opt[:redo_flag]
            query = ['updated_at < ? and updated_at > ?', Time.now - 1.day, Time.now - 15.day]
            listings = Listing.unscoped.latlngs.where('listings.status != 1 and listings.status < 10')
          else
            query = opt[:query]
            listings = Listing.unscoped.latlngs
          end
          listings = listings.where(query).order('id desc').limit(opt[:limit])
          if opt[:target]
            if opt[:target] == 'propertylink' #Property Link - Bozzuto Jersey and NY
              listings = listings.where('origin_url like ?', "%propertylink%").where("formatted_address like ? OR formatted_address like ?", "%NJ 0%","%NY 1%")
            elsif opt[:target] == 'securecafe' #SecureCafe Format - Bozzuto Jersey and NY
              listings = listings.where('origin_url like ?', "%securecafe%").where("formatted_address like ? OR formatted_address like ?", "%NJ 0%","%NY 1%")
            elsif opt[:target] == 'bostonbozzuto'
              listings = listings.where('origin_url like ?', "%securecafe%").where('formatted_address like ?', "%MA 0%")
            elsif opt[:target] == 'phillybozzuto'
              listings = listings.where('origin_url like ?', "%securecafe%").where('formatted_address like ?', "%PA 1%")
            elsif opt[:target] == 'equityresidential'
              listings = listings.where('origin_url like ?', "%equityapartments%").where("formatted_address like ? OR formatted_address like ?", "%NJ 0%","%NY 1%")
            elsif opt[:target] == 'equityresidentialboston'
              listings = listings.where('origin_url like ?', "%equityapartments%").where('formatted_address like ?', "%MA 0%")
            elsif opt[:target] == 'chicagobozzuto'
              listings = listings.where('origin_url like ?', "%securecafe%").where('formatted_address like ?', "%IL 6%")
            elsif opt[:target] == 'avaloncove'
              listings = listings.where('origin_url like ?', "%avalonbay%").where('formatted_address like ?', "%NJ 0%")
            elsif opt[:target] == 'avalonbayboston'
              listings = listings.where('origin_url like ?', "%avalonbay%").where('formatted_address like ?', "%MA 0%")
            elsif opt[:target] == 'exchangeplace'
              listings = listings.where('origin_url like ?', "%securecafe%").where("formatted_address like ?", "%NJ 0%")
            elsif opt[:target] == "twotree"
              listings = listings.where('origin_url like ?', "%streeteasy%").where("contact_name like ?", "%TwoTree%")
            elsif opt[:target] == 'forestcity'
              listings = listings.where('origin_url like ?', "%streeteasy%").where("contact_name like ?", "%Forest%")
            else
              listings = listings.where('origin_url like ?', "%#{opt[:target]}%")
            end
          end
        else
          listings = opt
        end
        num = 0
        listings.each do |listing|
          if !listing.url.nil?
            next if listing.url.include?('tfc.com') || (listing.mls_info_id && listing.mls_info.try(:name) == 'RealtyMx')
          end
          is_enable_flag = listing.is_enable?
          if opt[:target] == "phillybozzuto"
            site_name = "phillybozzuto"
          elsif opt[:target] == "bostonbozzuto"
            site_name = "bostonbozzuto"
          elsif opt[:target] == "equityresidentialboston"
            site_name = "equityresidentialboston"
          elsif opt[:target] == "equityresidential"
            site_name = "equityresidential"
          elsif opt[:target] == "chicagobozzuto"
            site_name = "chicagobozzuto"
          elsif opt[:target] == "avaloncove"
            site_name = "avaloncove"
          elsif opt[:target] == "avalonbayboston"
            site_name = "avalonbayboston"
          elsif opt[:target] == "exchangeplace"
            site_name = "exchangeplace"
          elsif opt[:target] == "forestcity"
            site_name = "forestcity"
          elsif opt[:target] == "twotree"
            site_name = "twotree"
          else
            site_name = get_site_name(listing)
          end
          next unless site_name
          if Spider::Improve::DeleteListing::PROC_DELETE.keys.include?(site_name)
            res = get_html(listing.url)
            if spider.redirect_to
              if site_name == 'elliman' || ['fenwickkeats', 'rutenbergrealtyny'].include?(site_name)
                listing.set_expired
                next
              end
            end
            if res.present?
              if res.code =~ /^2/
                doc = Nokogiri::HTML(res.body.to_utf8)
                hash = Spider::Improve::DeleteListing::PROC_DELETE[site_name].call(doc, listing )
                logger.info listing
                logger.info  hash
                if hash.present? && hash[:status]
                  listing.update_attributes(hash)
                end
              elsif res.code =~ /^4/
                listing.set_expired
                #listing.update_attributes(status: 1)
              end
              num += 1 if listing.is_expired? && is_enable_flag
              if num > 1000
                raise "delete too more"
                exit
              end
            end
          else
          end
        end
      end

      def more_info(listings = nil, opt = {})
        (listings || Listing.unscoped.latlngs.includes(:listing_detail).references(:listing_detail).where(opt[:query])
          .where('((listings.updated_at > ? and
                                           listings.updated_at <? and listings.contact_name is null or
                                           listings.contact_tel is null or listings.contact_tel = ?) or
                                           (listing_details.id is null or listing_details.description is null
                                           or listing_details.description = ?))',
                                           Time.now - 15.day, Time.now - 1.day, '', '').order('listings.id desc').limit(opt[:limit])).each do |listing|
                                             site_name = get_site_name(listing)
                                             next unless site_name
                                             next unless Spider::Improve::MoreInfo.respond_to?(site_name)
                                             if res = get_html(listing.url)
                                               if res.code == '200'
                                                 doc = Nokogiri::HTML(res.body.to_utf8)
                                                 hash = Spider::Improve::MoreInfo.send(site_name, doc, {flag: listing.flag, url: listing.url})
                                                 logger.info listing
                                                 logger.info  hash
                                                 if hash.present?
                                                   ## delete agents and broker object
                                                   hash.delete :agents
                                                   hash.delete :broker
                                                   hash.except! :listings
                                                   hash.except! :images if hash[:images] && hash[:images].empty?
                                                   listing.update_attributes(hash)
                                                   if hash[:description] || hash[:amenities]
                                                     listing.build_listing_detail unless listing.listing_detail
                                                     listing.listing_detail.description = hash[:description] if hash[:description]
                                                     listing.listing_detail.amenities = hash[:amenities] if hash[:amenities]
                                                     listing.listing_detail.save
                                                   end
                                                 end
                                               elsif res.code =~ /^4/
                                                 listing.set_expired
                                                 #listing.update_attributes(status: 1)
                                               end
                                             end
                                           end
      end

      def image(listings = nil,opt={})
        (listings ? listings : Listing.unscoped.latlngs.enables.where('updated_at > ? and
                                   updated_at <? and listings.listing_image_id is null', Time.now - 30.day, Time.now - 1.day)
          .where("origin_url like ?", "%#{opt[:target]}%").order('id desc').limit(opt[:limit])).each do |listing|
          site_name = get_site_name(listing)
          next unless site_name
          next unless Spider::Improve::Image.respond_to?(site_name)
          if res = get_html(listing.url)
            if res.code == '200'
              doc = Nokogiri::HTML(res.body.to_utf8)
              l_img = {url: listing.url}
              Spider::Improve::Image.send(site_name, doc, l_img)
              logger.info listing
              logger.info l_img
              if l_img[:images].present?
                l_img[:images].each do |img|
                  ListingImage.where(listing_id: listing.id).where(img).first_or_create
                  # listing.listing_images.where(img).first_or_create
                end
              end
            elsif res.code =~ /^4/
              listing.set_expired
              #listing.update_attributes(status: 1)
            end
          end
        end
      end

      def limit_image(num = 1)
        imgs = ListingImage.group(:listing_id).count
        ids = [-1]
        imgs.each do |k, v|
          ids << k  if v < num
        end
        listings = Listing.enables.where("listing_image_id is null or id in (#{ids.join(',')})")
        image(listings)
      end

      def get_html(url)
        begin
          # RestClient.get(url).to_utf8
          res = spider.get url
          #if res.code =~ /^2/
          #  res.body
          #else
          #  nil
          #end
        rescue =>e
          return  nil
        end
      end

      def change_kwnyc_image
        listings = Listing.enables.where('origin_url like ?', '%kwnyc%')
        listings.each do |l|
          l.images.where('origin_url like ?', '%thumbs%').destroy_all
        end
        listings.reload
        image(listings)
      end
      def set_listing_status_everyday(listing)
        return if listing.updated_at > Time.now - 30.hour
        arrs = ['citi-habitats']
        if arrs.include?(listing.broker_site_name)
          listing.set_expired
          #listing.status = 1
          #listing.save
        end
      end

      def fix_citi_habitat_beds
        listings = Listing.enables.rentals.where('origin_url like ?', '%citi-habitats%').where(beds: 0).where('price > 4000 and score_price < 7')
        citi = Spider::CitiHabitats.new
        listings.each do |l|
          res = spider.get l.url
          if res.code == '200'
            doc = Nokogiri::HTML(res.body)
            title = doc.css('title').text.strip
            if title =~ /^404/
              l.set_expired
              #l.status = 1
              #l.save
            end
            opts = citi.retrieve_listing(doc, l.url, flag: Settings.listing_flags.rental)
            Rails.logger.info l
            if opts[:beds] && opts[:beds].to_i != l.beds
              l.beds = opts[:beds]
              l.score_price = nil
              l.save
            end
          else
            l.set_expired
            #l.status = 1
            #l.save
          end
        end
      end
      def fix_citi_habitats_address opt={limit: 1,is_full_address: true}
        listings = Listing.enables.rentals.where(is_full_address: opt[:is_full_address]).where('origin_url like ?', '%citi-habitats%').limit opt[:limit]
        listings.each do |listing|
          res = spider.get listing.url
          if res.code == '200'
            doc = Nokogiri::HTML(res.body)
            title = doc.css('title').text.strip
            if title =~ /^404/
              listing.set_expired
              #listing.status = 1
              #listing.save
            end
            opts = Spider::CitiHabitats.new.retrieve_listing(doc, listing.url, flag: Settings.listing_flags.rental)
            if opts && opts[:lat] && opts[:lng]
              if listing.lat != opts[:lat].to_f || listing.lng != opts[:lng].to_f
                listing.cancel_listing_places
                listing.cancel_cal_transport_distances
                listing.political_area = nil
                listing.title = nil unless listing.is_full_address
                images = opts.delete :images
                listing.update_attributes(opts)
                if images.present?
                  images.each do |img|
                    listing.images.where(img).first_or_create
                  end
                end
              end
            else
              listing.set_expired
              #listing.status = 1
              #listing.save
            end
          end
        end
      end

      def expired_buildings_for_multi_listings_by_urls(urls)
        url = urls.first.split('#').first
        Listing.where('origin_url like ?', "#{url}%").where.not(origin_url: urls).update_all status: 1
      end
    end
  end
end
