module Spider
  module NYC
    class Gonofee < Spider::NYC::Base
      def initialize
        super
        @simple_listing_css = ".Normal .RealEstateLink a"
        @listing_image_css = ".photo-frame tr td a"
      end

      def domain_name
        'http://gonofee.com'
      end

      def base_url
        domain_name + "/no-fee-apartments/agentType/ViewSearch"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        max_id = 2
        (0..max_id).map do |i|
          url = URI.escape(base_url + "/currentpage/#{i+1}.aspx")
          [url, 1]
        end
      end

      def get_listing_url simple_doc
        abs_url simple_doc.attr("href")
      end

      def retrieve_detail(doc, listing)
        latlng = doc.css("#Body #Form script").text.match(/address\s+\=\s+\"(.+)\"\;/)
        if latlng.present?
          listing[:lat] = latlng[1].split(",").first
          listing[:lng] = latlng[1].split(",").last
        end
        l_doc = doc.css("#propertycontainer")
        listing[:title] = l_doc.css("#rightcolumn .stats .hedbig").text.strip
        listing[:unit] = l_doc.css("#rightcolumn .stats .hedsmall").text.split("#").last.strip
        listing[:unit] = listing[:unit].split(/\s/).first if listing[:unit].size > 5
        details =  l_doc.css("#rightcolumn .stats").text.split("\r\n\t").reject(&:blank?).map(&:strip)
        details.each_with_index do |li, i|
          listing[:price] = details[i+1].gsub(/\D+/, "") if li.match(/rent/i)
          listing[:beds] = details[i+1].to_f if li.match(/bed/i)
          listing[:baths] = details[i+1].to_f if li.match(/bath/i)
          listing[:sq_ft] = details[i+1].to_f if li.match(/Sq\. Foot/i)
        end
        listing[:description] = l_doc.css("#rightcolumn .star").text.strip
        listing[:no_fee] = true
        retrieve_images(l_doc, listing)
        retrieve_broker(l_doc, listing)
        retrieve_open_houses(l_doc, listing)
        listing[:contact_tel] = listing[:broker][:tel]
        listing[:contact_name] = listing[:broker][:name]
        listing[:zipcode] = listing[:broker][:zipcode]
        listing[:flag] = get_flag_id("rental")
        listing
      end

      def retrieve_broker(doc, listing)
        listing[:broker] = {
          name: "K&R Realty Management",
          tel: "2123605092",
          zipcode: "10026",
          email: "rent@gonofee.com",
          street_address: "316 West 118 Street"
        }
      end

      def retrieve_open_houses doc, listing
        open_houses = []
        holder = doc.css("#holder44").to_html.split("<br>").map{|o| o.remove("<div id=\"holder44\">").remove("</div>")}
        holder.each do |oh|
          if oh.match(/[\d\:]\s*+\w{2}\s+\-/)
            weeks = oh.split(/[\d\:]+\s[A-z]{2}\s+\-/).first.split("and").join(",").split(",")
            duration = oh.match(/([\d\:]+\s*[A-z]{2}\s*\-\s*[\d\:]+\s*[A-z]{2})/)[1]
            weeks.each do |week|
              open_date = Date.parse(week.strip)
              begin_time = Time.parse(duration.split("-").first.strip)
              end_time = Time.parse(duration.split("-").last.strip)
              open_houses << {open_date: open_date, begin_time: begin_time, end_time: end_time}
            end
          end
        end
        listing[:open_houses] = open_houses if open_houses.present?
      end

      def retrieve_images(doc, listing)
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
