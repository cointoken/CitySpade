module Spider
  module NYC
    class Brodskyorg < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#TABLE_1 tr td a"
        @listing_image_css  = "#gallery img"
      end

      def domain_name
        'http://www.brodskyorg.com'
      end

      def base_url(flag = 'rental')
        domain_name + "/search-apartments.html"
      end

      private :domain_name, :base_url

      def page_urls(flag)
        param_opts = {action: "search"}
        url = URI.escape(base_url(flag))
        [[url, param_opts]]
      end

      def self.enable_urls
        urls = []
        res = RestClient.post("http://www.brodskyorg.com/search-apartments.html", {action: "search"})
        if res.code.to_s == "200"
          Nokogiri::HTML(res.body).css("#TABLE_1 tr td a").each_with_index do |doc, i|
            urls << "http://www.brodskyorg.com" + doc.attr("href") if i % 3 == 0
          end
        end
        urls
      end

      def get_listing_url simple_doc
        abs_url simple_doc["href"]
      end

      def listings(opts={})
        page_urls(opts).each do |url_opt|
          opt = url_opt.last
          url = url_opt.first
          Rails.logger.info url
          @logger.info 'post', url
          res = post(url, opt)
          if res.code == '200'
            Nokogiri::HTML(res.body).css(@simple_listing_css).each_with_index do |simple_doc, index|
              next if index % 3 != 0
              listing = retrieve_listing(simple_doc)
              next unless listing
              next if !((listing[:title] || listing[:street_address]) || (listing[:lat] && listing[:lng]))
              listing[:city_name] ||= @city_name
              listing[:state_name] ||= @state_name
              check_title(listing)
              check_flag(listing)
              if block_given?
                @logger.info listing
                yield listing
              else
                @logger.info listing
                listing
              end
            end
          else
            []
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        res = get(get_listing_url(doc))
        if res.code == "200"
          l_doc = Nokogiri::HTML(res.body)
          listing[:url] = get_listing_url doc
          unit = listing[:url].split("/").last
          if unit.include? "unit"
            listing[:unit] = unit.match(/unit\-(\d+)\.html/)[1]
          else
            listing[:unit] = unit.split("-").last.remove(".html")
          end
          listing[:flag] = get_flag_id "rental"
          listing[:no_fee] = true
          l_doc.css("#threeColumnMid .black-link").text.strip.split("\n").each do |l|
            listing[:title] = l.strip.gsub(/\s\-\s/,"-") if l.strip.match(/\A\d{2,}/)
            listing[:zipcode] = l.gsub(/\D+/, "") if l.strip.match(/\,/)
          end

          agents = []
          mid_array = l_doc.css("#threeColumnMid p").text.strip.split("\n").reject(&:blank?)
          mid_array.each_with_index do |l, i|
            listing[:contact_tel] = l.gsub(/\D+/, "") if l.match(/T:/)
            if l.match(/@/)
              agent = {}
              agent[:name] = mid_array[i - 1].strip
              agent[:email] = l.strip
              agents << agent
            end
          end
          listing[:agents] = agents
          listing[:contact_name] = agents[0][:name] if agents[0].present?
          listing[:beds] = l_doc.css("#threeColumnRight .apartmentLeft").text.split("/").first.strip.to_f
          listing[:baths] = l_doc.css("#threeColumnRight .apartmentLeft").text.split("/").last.strip.to_f
          listing[:price] = l_doc.css("#threeColumnRight .apartmentRight").text.gsub(/\D+/, "")
          unless l_doc.css("#threeColumnRight .rte-wrapper ul li").blank? 
            listing[:amenities] = l_doc.css("#threeColumnRight .rte-wrapper ul li").map{|li| li.text.strip}            
          end
          # listing[:amenities] = l_doc.css("#threeColumnRight .rte-wrapper ul li").text.split(" ")
          listing[:description] = l_doc.css("#threeColumnRight .rte-wrapper p").text.strip
          listing[:flag] = 1
          get_detail(l_doc, listing)
          retrieve_broker(l_doc, listing)
        end
        listing
      end

      def get_detail(doc, listing)
        retrieve_images(doc, listing)
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "The Brodsky Organization",
          street_address: "400 West 59th Street",
          zipcode: "10019",
          tel: "2123155555",
          website: domain_name,
          introduction: %q{
            The Brodsky Organization is one of Manhattan's premier developer-owner-managers of luxury rental and condominium apartments, as well as commercial, mixed-use and retail spaces.
For over 60 years, The Brodsky Organization has been building and managing properties in the most desirable locations in New York City.
 Nathan Brodsky began rehabilitating brownstones and apartment buildings in Greenwich Village in 1951, and since then The Brodsky Organization has dedicated itself to providing attractive, affordable living spaces for New Yorkers. Nathan's son, Daniel Brodsky, joined the effort in 1970, and today, a third generation of the family, represented by Dean Amro, Alexander Brodsky and Thomas Brodsky, is continuing the tradition while bringing new insight about today's marketplace to the business.
 The Brodsky Organization takes pride in maintaining resident satisfaction with a caring management team and attention to detail.
 All apartments offer intelligently designed floor plans-many with breathtaking views-and are located in some of the most desirable neighborhoods in Manhattan.
 The company has developed more than 7,500 apartments in 80 buildings, which include charming brownstone buildings in the historic Greenwich Village, Chelsea and Upper East Side neighborhoods; stately prewar, renovated doorman buildings on the Upper West and Upper East Side; and newly constructed high-rise luxury rental buildings with expansive amenities in Battery Park, the Upper West Side and throughout the Midtown areas on both the east and west sides of Manhattan.
 The Brodsky Organization provides homes for a variety of tastes and income levels, from affordable to upscale rentals, and does not charge brokerage fees.
          }
        }
      end

    end
  end
end
