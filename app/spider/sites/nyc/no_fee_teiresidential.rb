module Spider
  module NYC
    class Teiresidential < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".property-dropdown-container .quickglance-icons-2 a"
        @listing_image_css  = ".col-containers .col-interior .carousel ul li a img"
      end

      def domain_name
        "http://teiresidential.com"
      end

      def base_url
        domain_name + "/rental-availabilities.php"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        [[base_url, 1]]
      end

      def self.enable_urls
        urls = []
        res = RestClient.get("http://teiresidential.com/rental-availabilities.php")
        if res.code.to_s == "200"
          Nokogiri::HTML(res.body).css(".property-dropdown-container .quickglance-icons-2 a").each do |doc|
            urls << "http://teiresidential.com/" + doc.attr("href") if doc.css("img").attr("src").value.match(/view\-details/i)
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        if simple_doc.css("img").attr("src").value.match(/view\-details/i)
          abs_url simple_doc.attr("href")
        else
          nil
        end
      end

      def retrieve_detail doc, listing
        listing[:no_fee] = true

        latlng = doc.css("#container script").text.match(/LatLng\((.+)\,\s+(.+)\)/)
        if latlng.present?
          listing[:lat] = latlng[1].strip
          listing[:lng] = latlng[2].strip
        end

        details = doc.css('.col-containers .col-interior .table tr')
        details.each do |tr|
          listing[:title] = tr.text.strip.split("\n")[1] if tr.text.match(/address/i)
          listing[:raw_neighborhood] = tr.text.strip.split("\n")[1].strip if tr.text.match(/\narea/i)
          listing[:unit] = tr.text.strip.split("\n")[1].strip if tr.text.match(/unit/i)
          listing[:flag] = get_flag_id(tr.text.strip.split("\n")[1]) if tr.text.match(/type/i)
          listing[:price] = tr.text.strip.split("\n")[1].gsub(/\D+/, "") if tr.text.match(/price/i)
          listing[:beds] = tr.text.strip.split("\n")[1].to_f if tr.text.match(/bed/i)
          listing[:baths] = tr.text.strip.split("\n")[1].to_f if tr.text.match(/bath/i)
          listing[:description] = tr.text.strip.split("\n")[1].to_s + "No Fee." if tr.text.match(/description/i)
        end
        listing[:amenities] = doc.css(".col-containers .ul-push li span").to_html.split("</span><span>").map do |amen|
          amen.strip.gsub(/[(<span>)(<\/span>)]/, "")
        end
        retrieve_broker(doc, listing)
        retrieve_agents(doc, listing)
        retrieve_images(doc, listing)
        if listing[:agents].first.present?
          listing[:contact_name] = listing[:agents].first[:name]
          listing[:contact_tel] = listing[:agents].first[:tel]
        end
        if listing[:broker]
          listing[:contact_name] ||= listing[:broker][:name]
          listing[:contact_tel] ||= listing[:broker][:tel]
        end
        listing
      end

      def retrieve_images doc, listing
        listing[:images] = []
        doc.css(@listing_image_css).each do |imgdoc|
          listing[:images] << {origin_url: imgdoc['src']}
        end
      end

      def retrieve_agents doc, listing
        agents = []
        agent = {}
        doc.css(".col-containers .col-interior .table tr").each do |tr|
          if tr.text.match(/agent/i)
            agent_detail = tr.text.strip.split("\n").reject(&:blank?)
            agent_detail.slice!(0)
            agent[:name] = agent_detail[0].strip
            agent_detail.each do |detail|
              agent[:tel] = detail.gsub(/\D+/, "") if detail.match(/[\d\-\(\)]+/)
              agent[:email] = detail.strip if detail.match(/@/)
            end
          end
        end
        agents << agent
        listing[:agents] = agents
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Time Equities Brokerage, LLC.",
          website: domain_name,
          tel: "2122066044",
          street_address: "55 Fifth Avenue",
          zipcode: "10003",
          introduction: %q{
            The Time Equities Residential Group consists of Time Equities Inc. Residential Department and Time Equities Brokerage LLC. The Residential Group serves as a sales and marketing consultant to Time Equities Inc.'s Acquisition and Development Department and provides Asset Management and Project Management services for residential properties in New York and New Jersey, specializing in the conversion of rental buildings to condominium and cooperative ownership and commercial buildings to residential use. Time Equities Inc. is the selling and rental agent for the vast majority of the residential properties in the portfolio, which are located in New York or New Jersey.

Time Equities, Inc. is the selling agent for the Sponsor/Developer in many cooperatives and condominiums. TEI also offers rental apartment listings on a no-fee basis to applicants who contact us directly, with a wide-range of properties located in NYC's most desirable neighborhoods, including the Upper West Side, Murray Hill, Greenwich Village, SoHo, the East Village and the Financial District.

View the Availabilities page for current rental and sales listings, open house schedules, applications and contact information to locate the apartment you are searching for.

Time Equities, Inc. is a full service real estate firm actively involved in the acquisition, development, conversion and management of commercial (office, retail, industrial) and residential properties throughout the US, Canada and Germany.
          }.strip
        }
      end

    end
  end
end
