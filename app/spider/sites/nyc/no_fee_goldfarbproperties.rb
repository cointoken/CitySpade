module Spider
  module NYC
    class Goldfarbproperties < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "div.results-main table tr td a"
        @listing_image_css  = ".highlights-rental a.rental_unit_gallery"
      end

      def domain_name
        'http://www.goldfarbproperties.com'
      end

      def base_url(flag = 'rental')
        domain_name + "/phpworx/index.php?cmd=property-worx&action=search_rental_units&search_action=get_results&region_names%5B%5D=Manhattan&region_names%5B%5D=The+Bronx&region_names%5B%5D=Queens&property_ids%5B%5D="
      end

      def self.enable_urls
        urls = []
        res = RestClient.get("http://www.goldfarbproperties.com/phpworx/index.php?cmd=property-worx&action=search_rental_units&search_action=get_results&region_names%5B%5D=Manhattan&region_names%5B%5D=The+Bronx&region_names%5B%5D=Queens&property_ids%5B%5D=")
        if res.code.to_s == "200"
          Nokogiri::HTML(res.body).css("div.results-main table tr td a").each do |doc|
            urls << "http://www.goldfarbproperties.com" + doc.attr("href") if doc.children.first.name == "small"
          end
        end
        urls
      end

      private :domain_name, :base_url

      def page_urls opt={}
        [base_url]
      end

      def get_listing_url simple_doc
        abs_url simple_doc["href"]
      end

      def listings(options={})
        page_urls.each do |url|
          @logger.info 'get url', url
          res = get(url)
          if res.code == '200'
            Nokogiri::HTML(res.body).css(@simple_listing_css).each do |doc|
              next unless doc.children.first.name == "small"
              listing = retrieve_listing(doc, url, options)
              next unless listing
              check_title listing
              if block_given?
                @logger.info listing
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

      def retrieve_listing doc, url=nil, options={}
        url = abs_url get_listing_url(doc)
        res = get(url)
        listing = {}
        if res.code == "200"
          l_doc = Nokogiri::HTML(res.body).css(".property-main")
          listing[:url] = url
          listing[:flag] = get_flag_id("rental")
          listing[:description] = l_doc.css(".property-content p").last.text
          # listing[:title] = l_doc.css("h1.rental_unit").text.split("|").first.strip
          p_content = Nokogiri::HTML(res.body).css(".highlights-rental p").text.strip.split("\n")
          listing[:title] = p_content.first.strip 
          listing[:city_name] = p_content[1].split(',')[0].strip
          listing[:state_name] = p_content[1].split(',')[1].split(' ')[0].strip
          listing[:amenities] = l_doc.css("ul").text.strip.split("\t").reject(&:blank?).map(&:strip)
          listing[:amenities].delete_if{|arr| arr.include?("Bathrooms") || arr.include?("Sq. Footage")}
          l_doc.css(".property-content .rental-small").each do |small|
            listing[:price] = small.text.gsub(/\D+/, "") if small.text.match(/rent\:/i)
          end
          l_doc.css("ul li").to_html.split("</li><li>").map{|l| l.gsub(/[(\<li\>)(\<\/li\>)]/, "")}.each do |li|
            listing[:beds] = li.split(":").last.strip.to_f if li.match(/bed/i)
            listing[:baths] = li.split(":").last.strip.to_f if li.match(/bath/i)
          end
          listing[:zipcode] = l_doc.css(".property-content .content .highlights-rental p").text.split("\n").reject(&:blank?).map(&:strip).last.split(",").last.split(" ").last
          listing[:raw_neighborhood] = l_doc.css(".property-content .content .highlights-rental p").text.strip.split("\n").last.split(",").first.strip
          listing[:is_full_address] = !!(listing[:title] =~ /^\d+\s/)
          listing[:no_fee] = true
          retrieve_images(l_doc, listing)
          retrieve_broker(l_doc, listing)
          listing[:contact_name] = listing[:broker][:name]
          listing[:contact_tel] = listing[:broker][:tel]
        end
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Goldfarb Properties",
          website: domain_name,
          tel: "9142353200",
          zipcode: "10801",
          street_address: "524 North Avenue",
          introduction: %q{
            Goldfarb Properties respects the privacy of its users. We sometimes collect information during your visits to understand what differentiates you from each of our millions of other users.
In order to demonstrate our commitment to your privacy, we have prepared this statement disclosing the privacy practices for the entire Goldfarb Properties site. Additional terms and conditions, if any, regarding the collection and use of your information may also be provided to you before you sign up for a particular service.
Here, you will learn what personally identifiable information of yours is collected, how and when we might use your information how we protect your information, who has access to your information, and how you can correct any inaccuracies in the information.
          }.strip
        }
      end

      def retrieve_images doc, listing
        imgdocs = doc.css(@listing_image_css)
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['href'])} if imgdoc['href'].present?
        end
        listing
      end

    end
  end
end
