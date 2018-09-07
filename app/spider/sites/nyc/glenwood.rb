module Spider
  module NYC
    class Glenwood < Spider::NYC::Base
      def initialize
        super
        @simple_listing_css = ".arhv-news"
        @desc_one_css = "html > body > div > div > div:nth-of-type(3) > p"
        @desc_two_css= "html > body > div > div > div:nth-of-type(3) > text():nth-of-type(8)"
      end

      def domain_name
        'http://www.glenwoodnyc.com/'
      end
      def base_url
        domain_name + "/properties/?p=viewPage.jsp&id=45&bedroom=&nhood=&price=0"
      end
      private :domain_name, :base_url

      def page_urls
        urls =[]
        doc = Nokogiri::HTML(open(base_url))
        doc.css(@simple_listing_css).each do |row|
          urls << domain_name + row.css('td a').first['href']
        end
        urls
      end

      def listings(options={})
        page_urls.each do |url|
          @logger.info 'get url', url
          res = get(url)
          if res.code == '200'
            Nokogiri::HTML(res.body).css('.prop').each do |doc|
              listing = retrieve_listing(doc, url, options)
              next unless listing
              check_title listing
              listing[:city_name] ||= @city_name
              listing[:state_name] ||= @state_name
              if block_given?
                @logger.info listing
                yield(listing)
              else
                p listing
              end
            end
          else
            []
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        phtml = doc.css('span').first
        link   = phtml.css('a').first
        titles = link['title']
        pstr = doc.css('h2').text.strip
        bedrooms = pstr.match(/(\S+)\s*Bedroom/)
        listing[:listing_type] = "rental"
        listing[:flag] = get_flag_id(listing[:listing_type])
        listing[:title] = titles
        return false unless is_full_address?(listing[:title])
        listing[:beds] = bedrooms.present? ? word_to_int(bedrooms[1]) : 0
        listing[:baths] = find_gw_bath(pstr)
        listing[:price] = (pstr.match(/\$\d+(\,\d{3})+/) ||['0'])[0].gsub(/\$|\,/,'')
        listing[:contact_name] = "Glenwood Realty"
        listing[:contact_tel]  = "18778425333"
        listing[:url]  = url
        listing[:neighborhood_name] = "manhattan"
        listing[:no_fee] = true
        # get image in detail page
        # listing[:images] = retrieve_images(doc, listing, url) if options[:image]
        res = get(listing[:url])
        if res.code == '200'
          doc_d = Nokogiri::HTML(res.body)
          get_detail(doc_d, listing)
        end
        listing
      end

      def word_to_int(str)
        words_hash = { "One"=> 1, "One1/2" => 1.5, "Two"=> 2,
          "Two1/2" => 2.5, "Three"=> 3, "Three1/2" => 3.5}
        if words_hash.has_key?str
          return words_hash[str]
        end
      end

      def find_gw_bath(pstr)
        if pstr.match(/(\S+)\s*Bath/).present?
          if pstr.match(/(\S+)\s*Bath/)[1] =="1/2"
            word_to_int(pstr.match(/(\S+)\s*(\S+)\s*Bath/)[1..2].join)
          else
            word_to_int(pstr.match(/(\S+)\s*Bath/)[1])
          end
        else
          return 1
        end
      end

      def get_detail(doc, listing)
        if doc.at_css(@desc_one_css).text.present?
          description = doc.css(@desc_one_css)
          listing[:description] = "#{description.first.text}\n #{description[1].text}"
          amenities = description[1].next_element
          if amenities
            listing[:description] += amenities.text
          end
          other_amenities = description[2].next_element
          if other_amenities
            listing[:description] += other_amenities.text
          end
        else
          description = doc.css(@desc_two_css)
          listing[:description] = description.first.text.gsub(/\r\n\t\t/, "")
          amenities = doc.css('.building li')
          if amenities
            amens = []
            buidling_desc = "\nBuiilding Description:\n"
            amenities.each do |item|
              buidling_desc += "#{item.text}\n"
              amens << item.text.gsub(/\:.*/, '')
            end
            listing[:amenities] = amens
            listing[:description] += buidling_desc
          end
        end
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
      end

      def retrieve_agents(doc, listing)
        # get all the agents
        agents = []
        agent = Hash.new
        agent_url = "http://www.glenwoodnyc.com/contact/"
        agent[:name] = "Glenwood Management"
        agent[:tel] = "18778425333"
        agent[:website] = agent_url
        agent[:email] = "EWaggelman@glenwoodnyc.com"
        agent[:origin_url] = agent_url
        agents << agent
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        # get broker
        listing[:broker] = {
          name: "Glenwood Luxury Apartment Rentals Corp",
          tel: "18778425333",
          email: "",
          website: domain_name,
          introduction: "All information is from sources deemed reliable but is subject to errors, omissions, changes in price, prior sale or withdrawal without notice. No representation is made as to the accuracy of any description. All measurements and square footages are approximate and all information should be confirmed by customer. All rights to content, photographs and graphics reserved to Broker. Customer should consult with its counsel regarding all closing costs, including without limitation the New York State 1% tax paid by buyers on residential properties over $1 million. Broker represents the seller/owner on Broker's own exclusives, except if another agent of Broker represents the buyer/tenant, in which case Broker will be a dual agent with designated agents representing seller/owner and buyer/tenant. Broker represents the buyer/tenant when showing the exclusives of other real estate firms. Broker actively supports equal housing opportunities"
        }
      end

      def retrieve_images(doc, listing)
        base_for_img ="http://glenwoodnyc.com/webdav/images/listings"
        sc_cont = doc.css('script')[7].content
        arr = sc_cont.scan(/\listings(.*?)jpg/i)
        listing[:images] = Array.new
        arr.each_with_index do |item,index|
          if(index % 2 == 0)
            listing[:images] << { origin_url: base_for_img + item.first.gsub(' ','%20') + "jpg"}
          end
        end
        if doc.css('img')
          listing[:images] << { origin_url: doc.css('img')[4]['src'] }
        end
        listing
      end
    end
  end
end
