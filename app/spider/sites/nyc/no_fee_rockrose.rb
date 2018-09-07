module Spider
  module NYC
    class Rockrose < Spider::NYC::Base
      def initialize
        super
        @simple_listing_css = ".units-tbody .unit"
        @get_url_args = 2
      end

      def domain_name
        'http://www.rockrose.com'
      end

      def base_url
        domain_name + "/residential/"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        [[base_url, 1]]
      end

      #      def self.enable_urls
      #urls = []
      #res = RestClient.get("http://www.rockrose.com/residential/")
      #if res.code.to_s == "200"
      #Nokogiri::HTML(res.body).css(@simple_listing_css).each do |doc|
      #urls << get_listing_url(doc)
      #end
      #end
      #urls
      #end

      def get_listing_url(simple_doc, listing = nil)
        return nil if simple_doc.css(".location .property-address").blank?
        tds = simple_doc.css('td')
        unit = tds[1].text.strip
        if listing
          listing[:title] = tds[0].css('a').children.first.text.strip
          listing[:unit] = unit
          # bb = tds[3].text.strip
          # bbs = bb.split('bdrm')
          # return nil unless bbs.size  > 1
          # listing[:beds] = bbs[0].to_f
          # listing[:baths] = bbs[1].to_f
          bbs = tds[3].to_html.split('<br>')
          return nil unless bbs.size > 1
          beds = bbs[0].gsub("<td class=\"centered\">","")
          baths = bbs[1].gsub("</td>","")
          listing[:beds] = beds.to_f
          listing[:baths] = baths.to_f
          listing[:raw_neighborhood] = tds[2].text.strip
          listing[:price] = tds[4].text.split('.').first.split('$').last.remove(/\D/)
        end
        URI.join(domain_name, simple_doc.css(".location .property-address").attr("href").value + "##{unit}").to_s
      end

      def retrieve_detail doc, listing
        l_doc = doc.css("#layout")
        listing[:flag] = get_flag_id("rental")
        listing[:description] = l_doc.css("#main .rich-text").text.strip
        listing[:raw_neighborhood] = l_doc.css("#tabs-2 p strong").text.strip
        listing[:contact_tel] = l_doc.css("#tabs-3 p strong").text.match(/at ([\d\-]+)/i)[1].gsub(/\D+/, "") if l_doc.css("#tabs-3 p strong").text.match(/at ([\d\-]+)/i).present?
        latlng = l_doc.css(".promo").text.strip.match(/LatLng\((.+)\,\s+(.+)\)/)
        if latlng.present?
          listing[:lat] = latlng[1]
          listing[:lng] = latlng[2]
        end
        retrieve_agents(l_doc, listing)
        retrieve_broker(l_doc, listing)
        retrieve_images(l_doc, listing)
        if listing[:agents].present?
          listing[:contact_tel] = listing[:agents].first[:tel]
          listing[:contact_name] = listing[:agents].first[:name]
        end
        listing[:contact_tel]   = listing[:broker][:tel] if listing[:contact_tel].blank?
        listing[:contact_name] ||= listing[:broker][:name]
        retrieve_open_house doc, listing if doc.css(".promo.white")[0].css("p").last.text =~ /Hours/
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        agent = {}
        agent_info = doc.css(".promo.white p").first.try(:text).try(:strip)
        if agent_info && agent_info.match(/contact/)
          info = agent_info.split("\r\n").map(&:strip)
          agent[:name] = info[0]
          agent[:tel] = info[1].gsub(/\D+/, "") if info[1].match(/[\d\-]/)
          if doc.css(".promo.white p")[6].present?
            address = doc.css(".promo.white p")[6].text.strip.split("\r\n").reject(&:blank?).map(&:strip)
            if address[1].present?
              agent[:address] = address[1]
              agent[:zipcode] = address.last.split(",").last.gsub(/\D+/, "")
            end
          end
          agents << agent
        end
        agents
      end

      def retrieve_images doc, listing
        listing[:images] = []
        doc.css("ul.slides li img").each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'])}
        end
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Rockrose Development Corp",
          tel: "2126919800",
          website: domain_name,
          introduction: %q{
            Founded in 1970, Rockrose Development Corp. is one of New York’s most pre-eminent and prolific developers.
              As an all-encompassing property owner, developer and manager, our visionary stance and commitment to excellence have established us as a leading force in New York real estate.
              With a hands-on management team who recognize the importance of exacting quality for demanding residential and commercial clients, the company continues to exceed expectations and create new standards.
              Henry Elghanayan carries on the family tradition with his son Justin.
          }
        }
      end

      def retrieve_open_house doc, listing
        arr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        listing[:open_houses] = []
        hours = doc.css(".promo.white")[0].css("p").last.children.
                map(&:text).reject(&:blank?).map &:strip
        hours = hours.delete_if{|hour| hour.include? "Hours"}
        opts = []
        hours.each do|hour|
          begin_and_end_time = hour.split(/\s/)[1..-1].join(" ")
          begin_time = begin_and_end_time.split("-")[0]
          end_time = begin_and_end_time.split("-")[1]
          open_dates = hour.split(/\s/)[0]
          if open_dates.split("-").size == 2
            opt_1 = open_dates.split("-")[0]
            opt_2 = open_dates.split("-")[1]
            for i in arr.index(opt_1)..arr.index(opt_2) do
              open_date = Date.parse(arr[i])
              open_houses = {open_date: open_date, begin_time: Time.parse(begin_time), end_time: Time.parse(end_time), loop: true, next_days: 7}
              listing[:open_houses] << open_houses
            end
          else
            open_date = Date.parse(open_dates)
            open_houses = {open_date: open_date, begin_time: Time.parse(begin_time), end_time: Time.parse(end_time), loop: true, next_days: 7}
            listing[:open_houses] << open_houses
          end
        end
        listing[:open_houses]
      end

    end
  end
end
