module Spider
  module NYC
    class Shnyc < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#MAIN table table table .featured .featured a.featured"
        @listing_image_css  = "#MAIN table table table table table table tr td a img"
      end

      def domain_name
        "http://www.sh-nyc.com"
      end

      def base_url
        domain_name + "/index.cfm"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        [[base_url, 1]]
      end

      def self.enable_urls
        urls = []
        res = RestClient.get("http://www.sh-nyc.com/index.cfm")
        if res.code.to_s == "200"
          Nokogiri::HTML(res.body).css("#MAIN table table table .featured tr td .featured a.featured").each do |doc|
            urls << "http://www.sh-nyc.com/" + doc.attr("href")
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc.attr("href")
      end

      def retrieve_detail doc, listing
        listing[:title] = doc.css(".listing_title").text.split(",").first.strip
        listing[:unit] = doc.css(".listing_title").text.split(",").last.gsub(/APT\s*\#/i, "").strip
        listing[:no_fee] = true
        doc.css("table table table .featured")[0].text.split("\r\n\t").reject(&:blank?).map(&:strip).each do |feat|
          listing[:raw_neighborhood] = feat.split(":").last.strip if feat.match(/area\:/i)
          listing[:price] = feat.gsub(/\D+/, "").to_i if feat.match(/rent/i)
          listing[:description] = feat.strip unless feat.match(/\:/)
        end
        listing[:amenities] = []
        if doc.css("table table table table.featured")[2].present?
          doc.css("table table table table.featured")[2].css("tr").each do |tr|
            listing[:beds] = tr.text.split(":").last.strip.to_f if tr.text.match(/bed/i)
            listing[:baths] = tr.text.split(":").last.strip.to_f if tr.text.match(/bath/i)
            listing[:listing_type] = tr.text.split(":").last.strip if tr.text.match(/property type/i)
            if tr.text.present?
              listing[:amenities] << tr.text.split(":").first.strip if tr.css("img").present? && tr.css("img").last["src"] =~ /v\.gif/
            end
          end
        end
        listing[:contact_name] = "S&H Equities"
        contact_msg = doc.css("table table table tr td table table.featured tr td").text.split(":")
        contact_msg.each do |msg|
          listing[:contact_tel] = msg.gsub(/\D+/, "") if msg.match(/\d{2,}\-/)
        end

        retrieve_broker(doc, listing)
        retrieve_open_house doc, listing if doc.css(".required").present?
        listing[:contact_name] = listing[:broker][:name] if listing[:contact_name].blank?
        listing[:contact_tel] = listing[:broker][:tel] if listing[:contact_tel].blank?
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "S&H Equities (NY) Inc.",
          website: domain_name,
          email: "rentals@sh-nyc.com",
          street_address: "98 Cutter Mill Rd.",
          zipcode: "11021",
          tel: "5164874090",
          introduction: %q{
            S&H Equities (NY) Inc., a real estate development and property management company was founded in 1995 by partners Serge Hoyda and Amir Chaluts.   Their visionary outlook helped reinvigorate the Lower East Side, making it one of the city's premiere locations. In other areas, the company developed a luxury condominium building on Manhattan's Upper East Side. Through innovative designs, superior construction, and hands-on supervision of our projects, S&H Equities has earned a reputation for offering quality living space as well as desirable retail locations in New York City's most coveted neighborhoods.
Real estate is as much about relationships as it is bricks and mortar. That's why at S & H Equities we have assembled a talented staff of dedicated professionals who offer years of experience and expertise in all areas of real estate.
S & H Equities (NY) Inc. is currently involved in projects ranging from gut renovations, ground up construction, new developments of rental and condominium housing, and commercial properties throughout the city. For more information contact our office at 516.487.4090.
          }.strip
        }
      end

      def retrieve_images doc, listing
        imgdocs = doc.css(@listing_image_css)
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: imgdoc['src']} if imgdoc['src'].present?
        end
        listing
      end

      def retrieve_open_house doc, listing
        listing[:open_houses] = []
        arr = doc.css(".required").to_html.split(/<br>/)
        arr.each do|arr|
          if arr =~ /OPEN HOUSE:/       
            open_date = Date.parse(arr.remove(/\<.+\>\s+OPEN HOUSE\:/).split(",")[0])
            begin_and_end_time = arr.remove(/\<.+\>\s+OPEN HOUSE\:/).split(",")[1].strip.split("-")
            begin_time = Time.parse(begin_and_end_time[0])          
            end_time = Time.parse(begin_and_end_time[1])
          end
          opts = arr.remove(/<\/span>/).strip.split(",")
          open_date = Date.parse(opts[0])
          begin_time = Time.parse(opts[1].split("-")[0])
          end_time = Time.parse(opts[1].split("-")[1])
          open_houses = {open_date: open_date, begin_time: begin_time, end_time: end_time}
          listing[:open_houses] << open_houses
        end
      end

    end
  end
end
