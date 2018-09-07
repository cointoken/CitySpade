module Spider
  module NYC
    class CitiHabitats < Spider::NYC::Base
      def initialize(opts={})
        super
        @opts[:accept_cookie] ||= true
        @listing_agent_css = "table td a"
      end

      def domain_name
        'http://www.citi-habitats.com'
      end
      def page_urls(opt={})
        base_url = domain_name + (get_flag_id(opt[:flag]) == 1 ? "/nyc-properties/for-rent" : "/real-estate/sales")
        urls = []
        res = get(base_url)
        if res.code == "200"
          max_num = Nokogiri::HTML(res.body).css(".darkblue a").map{|l| l['href'] && l['href'].split('/')
            .select{|a| a && a =~ /^\d+$/}.first.to_i}.max || 0
        end
        max_num ||= 6000
        #limit = opt[:limit] || 10000
        #max_num = [max_num, limit].min
        per   = 300
        pages = max_num / per
        pages = [100, pages].min
        (0..pages).each do |page|
          urls << "#{base_url}/#{per * page}/#{per}"
        end
        urls
      end
      def listings(options={})
        options[:flags] = %w(rent sale)
        options[:limit] ||= 10000
        options[:flags].each do |flag|
          @logger.info flag, 'begin http get sale type'
          options.merge! :flag => flag
          urls = page_urls(options)
          num = 0
          (urls).each do |url|
            @logger.info 'get url', url
            res = get(url)
            if res.code == '200'
              docs = Nokogiri::HTML(res.body).css('tr.cellboxOdd,tr.cellboxEven').map{|a| a}
              if docs.present?
                # docs.select!{|d| d['href'] =~ /^\// && d.css('b').present?}
                docs.each do |doc|
                  href = doc.css('td')[1]
                  next unless href #doc['href'].present?
                  href = href.css('a').first
                  next unless href
                  href = abs_url href['href']
                  next if href !~ /^http/
                  status = 0
                  # p_doc = doc.parent
                  if doc.text.include?('*In Contract')
                    status = 1
                  end
                  next if check_listing_and_update_state(href, status) && !options[:reget]
                  next if num > options[:limit]
                  num += 1
                  listing_res = get(href)
                  if listing_res.code == '200'
                    html = Nokogiri::HTML(listing_res.body)
                    listing = retrieve_listing(html, href, options)
                    next if !listing || listing.blank?
                    @logger.info listing
                    listing[:city_name] ||= @city_name
                    listing[:state_name] ||= @state_name
                    check_title listing
                    if status
                      listing[:status] = status
                    end
                    # next unless listing[:title] =~ /^\d/
                    if block_given?
                      yield listing
                    else
                      listing
                    end
                  end
                end
              else
                break
              end
            end
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        unless get_latlng(doc, listing)
          # return false
        end
        title = doc.css('.listing_h1').first# .text.strip
        return {} if title.blank?
        title = title.text.strip
        if title =~ /^\d+(\-\d+)?\s/
          listing[:title] = title
          listing.delete :lat
          listing.delete :lng
        else
          return {}
        #  listing[:title] = title
          #listing[:neighborhood_name] = title
          #listing[:is_full_address]   = false
        end
        price = doc.css('.listing_price')
        if price.first && price.first.text.strip =~ /^[A-Z]/
          listing[:neighborhood_name] = price.first.text.strip
        end
        desc = doc.css("#long_descr").first
        if desc
          listing[:description] = desc.text
        end
        listing[:price] = price.text.strip.gsub(/\D/, '')
        details = doc.css('.bottom_blue_table').first
        if details
          details = details.css('td.listing_agent_txt').map{|l| l.children.map{|l1| l1.text.strip}.delete_if(&:blank?).join("\n")}
          details.each_with_index do |detail, index|
            details_regexp.each do |key, value|
              if detail =~ value[:reg]
                if listing[key].blank?
                  d = details[index + 1]
                  listing[key] = value[:proc].call(d)
                end
                break
              end
            end
          end
        end
        listing[:url]   = url
        listing[:flag]  = get_flag_id(options[:flag])  if options[:flag]
        agent_detail = doc.css('td.bottom_blue_table')[1]
        if agent_detail && agent = agent_detail.parent.parent
          listing[:contact_name] = agent.css('td.top_blue_table b').first.text.strip
          return false unless get_contact_tel(agent_detail, listing)
        end

        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css("table td.bottom_blue_table").each do |listing_agent|
          agent = {}
          agent_img = listing_agent.css("tr td a img")
          next if agent_img.blank?
          tel_match = listing_agent.css("tr td .listing_agent_txt").text.strip.match(/C\:([\s\d\-]+)/)
          agent[:tel] = tel_match[1].gsub(/\D+/, "") if tel_match.present?
          agent[:email] = listing_agent.css("a b").text.try(:strip)
          agent[:name] = agent_img.first.attr("alt").split("-")[0].strip if agent_img.first.attr("alt").present?
          img_uri = agent_img.first.attr("src")
          img_uri.match(/^http:\/\//) ? agent[:origin_url] = img_uri : agent[:origin_url] = abs_url(img_uri)
          agent[:website] = get_agent_url(listing_agent)
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "Citi Habitats",
          website: domain_name,
          tel: "2126857777",
          introduction: %q{Citi Habitats supports a variety of charitable organizations in our dedicated effort to give back to the community. From collecting more than 1,000 backpacks and school supplies for underprivileged NYC-area children to raising nearly $29,000 to help fight our nation's No. 1 and No. 3 killers, heart disease and stroke, we systematically rise to the challenge of making our city, and our country, a better place for all to live in.}
        }
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgdocs = doc.css('a img.listing_img').map{|img| img[:src]}.select{|src| src.include?("www.citi-habitats.com/images/listing")}
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: imgdoc} if  imgdoc
        end
        listing
      end

      def get_latlng(doc, listing)
        srcs = doc.css("table img").map{|img| img[:src]}.select{|src| src =~ /maps\.googleapis\.com\/maps/}
        if srcs.present?
          param = Rack::Utils.parse_nested_query URI(srcs.first).query
          latlng = param['center']
          if latlng.present? and latlng !~ /^0/
            listing[:lat] = latlng.split(',').first
            listing[:lng] = latlng.split(',').last
            return true
          end
        end
        return false
      end

      def get_contact_tel(doc, listing)
        docs = doc.css('td table td.listing_agent_txt').map{|a| a.text.strip}
        if docs.present?
          ["O:", "D:","C:", "F:"].each do |t|
            ss = docs.select{|s| s == t}
            if ss.present?
              i = docs.index t
              if docs[i + 1]
                listing[:contact_tel] = docs[i + 1].gsub(/\D/, '') if docs[i + 1]
                return true
              else
                return false
              end
            end
          end
        end
        return false
      end

      def details_regexp
        {
          beds: {reg: /^bedroom/i, proc: ->(str) { beds_num(str)}},
          baths: {reg: /^bath/i, proc: ->(str) {str.gsub(/\+/, '')}},
          sq_ft: {reg: /^sq\.ft/i, proc: ->(str){str.gsub(/\D/, '')}},
          amenities: {reg: /^amenities/i, proc: ->(str){str.split(/\n/).select{|s| s.present?}}}
        }
      end
      def beds_num(str)
        nums = {
          one: 1,
          two: 2,
          three: 3,
          four: 4,
          five: 5,
          six: 6,
          seven: 7,
          eight: 8,
          nine: 9,
          ten: 10
        }
        # A Junior 4 or JR4 is a one-bedroom apartment with a separate dining room or a small bedroom or office
        return 1 if str =~ /Junior 4/i or str =~ /JR4/
        keys = str.split(' ').map{|s|s.downcase.to_sym}
        k = nil
        keys.each do |key|
          if nums.keys.include? key
            k = key
            break
          end
        end
        if k
          nums[k]
        else
          d = str.gsub(/\D/,'')
          if d.present?
            d
          else
            0
          end
        end
      end

      def check_listing_and_update_state(href, status)
        listing = Listing.where(origin_url: href).first
        if listing
          #if listing.updated_at < Time.now - 8.hours && listing.status != 0
          #if listing.status == 1 && status == 0
          #listing.status = status
          #listing.origin_url = href
          #listing.save
          #end
          listing.status = status
          listing.save
          #end
          return true
        else
          return false
        end
      end

      def get_title doc, listing = {}
        tl = doc.css('.listing_h1').first
        if tl
          listing[:title] = tl.text.strip
        end
      end
    end
  end
end
