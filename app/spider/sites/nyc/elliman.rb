module Spider
  module NYC
    class Elliman < Spider::NYC::Base
      def initialize(opts = {accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                             user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36',
                             accept_cookie: true})
        @listing_agent_css = ".w_listitem_agent_info a.n"
        super
      end

      def domain_name
        'http://www.elliman.com'
      end
      def base_url
        domain_name + '/new-york-city/'
      end

      def post_url(flag)
        if flag =~ /sale/
          'http://www.elliman.com/search/process/for-sale'
        else
          'http://www.elliman.com/search/process/for-rental'
        end
      end

      def boroughs_params
        {
          queens:{
            loc_r_3: [406,257,123,170,412,295,89,324,169,401,187,183,191,188,362,2,270,64449,46,195,325,164,310,371,289,292,133,233,54,165,285,10,410,422,201,253,234,174,56,375,98,278,71234,332,284,305,368,419,63,212,417,298,83,420,317,359,185,196,403,297,321,210,167,1],
            data_region: '3|2'
          },
          manhattan: {
            loc_r_4_2: [13, 58, 16],
            loc_r_4_1: [60,130,27],
            loc_r_4_3: [55,39,28,107,42,35,21,31,53],
            loc_r_4_4: [52,40,36,351,85,30],
            loc_r_4_5: [15,18,26,32,25,24,23,73,38,85649,57,70809,49,29],
            loc_r_4_6: [56],
            data_region: '4|0'
          },
          brooklyn:{
            loc_r_5: [65297,106,67,126,65721,61,385,349,20,369,104,50,96,66,65,45,93,66145,341,44,66569,81,68,78,352,344,348,66993,67417,67841,79,381,59,400,68265,68689,127,113,17,87,354,64,64873,69113,350,51,2121,399,425,41,14,122,94,342,392,69537,340,105,118,69961,43,92],
            data_region: '5|1'
          }
        }
      end

      def init_params(flag,opt)
        if flag == 'sale'
          {
            search_by_school_district: 0,
            i_search_form_submitted: 1,
            type: 'advanced',
            sale_rental: Settings.listing_flags.sale,
            date_listed_from: (Time.now - 30.day).strftime("%m-%d-%y"),
            date_listed_to: Time.now.strftime('%m-%d-%y')
          }.merge! opt
        else
          {
            search_by_school_district: 0,
            i_search_form_submitted: 1,
            type: 'advanced',
            sale_rental: Settings.listing_flags.rental,
            price_from: '1,200',
            price_to: '155,500',
            date_listed_from: (Time.now - 60.day).strftime("%m-%d-%y"),
            date_listed_to: Time.now.strftime('%m-%d-%y')
          }.merge! opt
        end
      end

      def page_url(first_url, page)
        first_url.sub(/(\/search-\d+)?\?/, "/search-#{page}?").sub(/\&?sk\=\d/, '') + '&sk=3'
      end


      private :domain_name, :base_url

      def listings(options={})
        (options[:boroughs]||[:manhattan, :queens, :brooklyn]).each do |borough|
          %W(rent sale).each do |flag|
            @logger.info :sale, 'begin http get sale type for ' + domain_name
            first_url = nil
            options.merge! :flag => flag
            (1..options[:pages] || 24).each do |page|
              if page == 1
                res = post(post_url(flag), init_params(flag, boroughs_params[borough]))
                first_url = URI.join(base_url, redirect_to.to_s).to_s if res.code == '200' && redirect_to
                res = res.body
              else
                res = RestClient.get(page_url(first_url, page))
              end
              @logger.info 'get url', page_url(first_url, page)
              if res
                docs = Nokogiri::HTML(res).css('.w_listitem')
                break if docs.size < 7
                docs.each do |doc|
                  begin
                    listing = retrieve_listing(doc, base_url, options)
                    p listing
                  rescue => e
                    p e.backtrace
                    @logger.info listing, e
                    @logger.info e.backtrace.inspect
                    next
                  end
                  next unless listing
                  check_title listing
                  listing[:city_name] ||= @city_name
                  listing[:state_name] ||= @state_name
                  listing[:status] ||= 0
                  if block_given?
                    yield(listing)
                  else
                    listing
                  end
                end
              else
                []
              end
            end
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        # title = doc.css('.listing_address a').first.text
        return false unless decorate_title(doc, listing)
        if doc.css('.w_msg_message strong').first && doc.css('.w_msg_message strong').first.text.include?('ed')
          if doc.css('.w_msg_message strong').first.text.downcase.include?('rent')
            listing[:status] = 1
          else
            listing[:status] = 2
          end
        end
        listing[:url]  = abs_url(doc.css('.listing_address a').first['href'])
        if img = doc.css('img').first && img.present? && img['src'].include?('membership_sra')
          listing[:status] = 1
          return listing
        end
        listing[:flag] = get_flag_id(options[:flag])  if options[:flag].present?
        more_info(listing)

        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(".w_listitem_agents ul li").each do |agent_doc|
          agent = {}
          agent[:name] = agent_doc.css(".w_listitem_agent_info a.n").text.strip
          agent[:tel] = agent_doc.css(".w_listitem_agent_info .tel.first_tel").text.gsub(/\D/, "")
          # agent[:email] = agent_doc.css(".w_listitem_agent_info a.email").text.strip # email被保护了，获取不到
          website = agent_doc.css(".w_listitem_agent_info a.n").first.attr("href")
          agent[:website] = website.match(/http\:/).present? ? website : abs_url(website)
          agent[:origin_url] = agent_doc.css(".w_listitem_agent_photo img").first.attr("src") if agent_doc.css(".w_listitem_agent_photo img").present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Douglas Elliman",
          website: domain_name,
          introduction: %q{Established in 1911, Douglas Elliman has grown to become the largest regional and the nation’s fourth largest real estate company, with a current network of more than 4,000 agents in over 70 offices throughout Manhattan, Brooklyn, Queens, Long Island (including the Hamptons and North Fork), Westchester and Putnam Counties, as well as South Florida and California. In addition, via a strategic partnership with Knight Frank Residential, Douglas Elliman’s powerful network extends to 43 countries across six continents.
At Douglas Elliman, we are passionate about delivering exceptional consumer experiences. By offering a complete suite of real estate services, we ensure that we meet our consumers’ every need. From sales and rentals, retail and commercial, to mortgage, new development marketing, property management and title insurance, we have experts in every field to guide you skillfully from beginning to the end of your real estate journey.
We believe that access to the best and most timely information can dramatically shape our decisions. Today’s consumer needs a trusted resource that can separate signal from noise and help them navigate the complex process that real estate has become. With our extensive knowledge in every aspect of the field, and fueled by consumer research and insights, we are the go-to source for information and education. As committed to growth and innovation as we are to our consumers, we have launched AskElliman.com, our groundbreaking new web feature that facilitates open communication with consumers, allowing them to tap into the wealth of knowledge of top industry experts.}
        }
      end

      def more_info(listing)
        doc = Nokogiri::HTML(RestClient.get(listing[:url]))
        info = doc.css('.w_listitem_description ul')

        if doc.css('.listing_fees').text.strip == 'No Fee'
          listing[:no_fee] = true
        end
        # listing[:neighborhood_name] = doc.css('.listing_neighborhood a').first.text.split('-').last.strip
        listing[:listing_type]      = doc.css('.listing_extras').first.text.split(',').first.strip
        beds = info.css('.listing_features').first.text
        if beds && beds.include?('Studio')
          listing[:beds]              = 0
        else
          if beds.strip =~ /^\./
            listing[:beds] = 0.5
          else
            beds = beds.match(/(\d+\.?5?)\sBed/i)
            if beds
              listing[:beds]              =  beds[1]
            else
              listing[:beds]              =  0
            end
          end
        end
        listing[:baths]             = info.css('.listing_features').first.text.match(/(\d+\.?5?)\sBath/)[1]
        listing[:price]             = info.css('.listing_price').first.text.gsub(/Price\:|\$|\,/, '').strip
        broker = doc.css('.w_listitem_agent_info')
        listing[:contact_name] = broker.css('a').first.css('span').map{|d| d.text}.join(' ').strip
        listing[:contact_tel]  = broker.css('.tel').first.text.gsub(/[a-zO.:]/,'').strip.gsub(/\D/, '')
        retrieve_images(doc, listing)
        get_detail(doc, listing)
        listing
      end

      def get_detail(doc, listing)
        desc = doc.css('.w_listitem_copy p').map{|t| t.children.select{|s| s.name !~ /script/}.map{|s| s.text.strip}.join("\n")}.join("\n")
        if desc.present?
          listing[:description] = desc
        end
        amen = doc.css('.w_listitem_description h5,.w_listitem_description ul')
        len = amen.size / 2
        (0...len).each do |l|
          am = amen[l]
          if am.name == 'h5' && am.text.downcase.include?('building details')
            amens = amen[l + len]
            if amens
              amens = amens.css('li').map{|t| t.text.strip}.delete_if{|t| t.blank? || t.include?('More')}
              listing[:amenities] = amens
            end
          end
        end
      end

      def decorate_title(doc, listing)
        title = doc.css('.listing_address a').first.text
        neigh = doc.css('li.listing_name').text.strip.split(/\,|\-/).first.try(:strip)
        return false unless title
        listing[:raw_neighborhood] = neigh
        titles = title.split(',')

        if titles.size == 1
          listing[:title] = titles.first
          true
        elsif titles.size > 1
          if  titles[1].strip =~ /^\d+\s/ && !titles[1].include?('-') && titles[1].gsub(/\d/, '').strip.size > 4
            listing[:title] = titles[1].strip
          elsif titles.first.strip.size > 10
            listing[:title] = titles.first.strip
          else
            return false
          end
          unit_index = titles.index{|s| s.include?(listing[:title])} + 1 
          listing[:unit] = titles[unit_index].split.first if titles[unit_index]  =~ /\d/
            #.last if titles.last.gsub(/\d/, '').strip.size < 5
          true
        else
          false
        end
      end

      def retrieve_images(doc, listing)
        image_class = doc.css('.w_listitem_gallery')
        listing[:images] = []
        if image_class.first
          image_url = image_class.first['data-gallery-rpc']
          if image_url.present?
            images_json = MultiJson.load(RestClient.get(abs_url(image_url)))
            screen = Nokogiri.HTML(RestClient.get(images_json["full_screen"])) if images_json["full_screen"].present?
            if screen.css("embed").present?
              src = screen.css("embed").attr("src").value
              image_urls = Nokogiri.HTML(RestClient.get(src.gsub(/EXPO\/GothamExpoAS3\.swf\?lp=/,"")))
              image_urls.css("gallery hires url").each do |url|
                listing[:images] << {origin_url: url.text.strip}
              end
              li = Listing.where(origin_url: listing[:url]).first
              li.images.destroy_all if listing[:images].present? && li.present? and !li.images.pluck(:origin_url).include?(listing[:images].first[:origin_url])
            end
            if listing[:images].blank?
              (images_json['photos'] || []).each do |img|
                listing[:images] << {origin_url: abs_url(img['full'])} unless abs_url(img['full']) =~ /no(.+)?photo/i
              end
            end
          end
        end
        listing
      end

      def get_title doc, listing = {}
        meta = doc.css('meta[property="og:title"]').first
        if meta
          tls = meta['content'].strip.split(',')
          listing[:title] = tls.first =~ /^\d/ ? tls.first : tls[1].strip
        end
      end
    end
  end
end
