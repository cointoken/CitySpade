module Spider
  module SF
    class Sfrealtors < Spider::SF::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '#search-results-list .listings .items .item h2 a'
        @listing_agent_css = ".contacts_agents .agent-container"
        @listing_image_css  = "#details_photo .photo .controls .thumbs a img"
        #@listing_callbacks[:image] =-> (img) {
        #}
      end

      def domain_name
        "http://www.sfrealtors.com/"
      end

      def base_url
        domain_name + "US/Real-Estate-Listings.html"
      end

      def page_urls(opts={})
        urls = []
        60.times do |t|
          urls << [base_url + "?page=#{t+1}", 0]
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail doc, listing
        listing[:title] = doc.css(".two-column-right .page-tools .item_address").text.split(",").first.strip
        doc.css(".two-column-right .page-tools .item_address span").each do |span|
          listing[:zipcode] = span.text.strip if span.text.match(/\d{5}/)
        end
        listing[:price] = doc.css("#details_info .top-info .price .green span").text.gsub(/\D/, "")
        doc.css("#details_info .details_characteristics_cnt table tr").each do |tr|
          listing[:beds] = tr.text.split(":").last.strip.to_f if tr.text.match(/beds/i)
          listing[:baths] = tr.text.split(":").last.strip.to_f if tr.text.match(/baths/i)
          listing[:sq_ft] = tr.text.split(":").last.strip if tr.text.match(/sqft/i)
          listing[:listing_type] = tr.text.split(":").last.strip if tr.text.match(/Property type/i)
          listing[:raw_neighborhood] = tr.text.split(":").last.strip if tr.text.match(/neighborhood/i)
          listing[:unit] = tr.text.split(":").last.strip.split("\r\n").first.strip if tr.text.match(/unit/i)
        end
        listing[:amenities] = doc.css("#details_info .features_list ul li").map do |li|
          li.text.split(":").last.strip if li.text.match(/:/)
        end.reject(&:blank?)
        listing[:description] = doc.css("#details_description").text.strip

        retrieve_agents doc, listing
        retrieve_broker doc, listing
        retrieve_open_houses doc, listing
        retrieve_images doc, listing

        if listing[:agents].present?
          listing[:contact_name] = listing[:agents].first[:name]
          listing[:contact_tel] = listing[:agents].first[:tel]
        else
          listing[:contact_name] = listing[:broker][:name]
          listing[:contact_tel] = listing[:broker][:tel]
        end
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(@listing_agent_css).each do |agent_doc|
          agent = {}
          agent[:name] = agent_doc.css(".agent-details h4").text.strip
          agent_doc.css(".agent-links li").each do |ph|
            agent[:tel] = ph.text.gsub(/\D/, "") if ph.text.match(/offc/i)
            agent[:mobile_tel] = ph.text.gsub(/\D/, "") if ph.text.match(/cell/i)
            agent[:fax_tel] = ph.text.gsub(/\D/, "") if ph.text.match(/fax/i)
          end
          agent[:office_tel] = agent[:tel]
          agent[:address] = agent_doc.css(".agent-links .address").text.split(",").first.strip
          agent[:origin_url] = agent_doc.css(".agent-photo img").first.attr("src") if agent_doc.css(".agent-photo img").present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "SFAR: Real Estate Listings, Homes for Sale",
          tel: "4154318500",
          email: "sfar@sfrealtors.com",
          street_address: "301 grove st.",
          zipcode: "94102",
          website: domain_name,
          introduction: %q{
          }
        }
      end

      def retrieve_open_houses doc, listing
        listing[:open_houses] = []
        doc.css("#details_info .open-house-cnt .open-house .open-house-line").each do |line|
          open_line = line.text.strip.split("\r\n").reject(&:blank?)
          open_date = Date.parse open_line.first
          begin_time = Time.parse open_line.last.strip.split("to").first
          end_time = Time.parse open_line.last.strip.split("to").last
          open_house = {open_date: open_date, begin_time: begin_time, end_time: end_time}
          listing[:open_houses] << open_house
        end
      end

      def retrieve_images doc, listing
        imgdocs = doc.css(@listing_image_css)
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: imgdoc['data-fullsrc']} if imgdoc['data-fullsrc'].present?
        end
        listing
      end
    end
  end
end
