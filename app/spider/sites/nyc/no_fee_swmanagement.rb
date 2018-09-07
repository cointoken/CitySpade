module Spider
  module NYC
    class Swmanagement < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#mytable .unitrow"
        @listing_image_css  = "#galleria img"
      end

      def domain_name
        'http://www.swmanagement.com'
      end

      def base_url(flag = 'rental')
        domain_name + "/aspsite/PropertyListings.aspx"
      end

      def self.enable_urls
        urls = []
        res = RestClient.get("http://www.swmanagement.com/aspsite/PropertyListings.aspx")
        if res.code.to_s == "200"
          Nokogiri::HTML(res.body).css("#mytable .unitrow").each do |simple_doc|
            aid = "aid=" + simple_doc.attr("aid")
            sta = "sta=" + simple_doc.attr("sta")
            blk = "blk=" + simple_doc.attr("blk")
            params = [aid, sta, blk].join("&")
            urls << "http://www.swmanagement.com/aspsite/unitDetails.aspx?" + params.gsub(/\s/, "%20")
          end
        end
        urls
      end

      private :domain_name, :base_url

      def page_urls opt={}
        [[base_url, 1]]
      end

      def get_listing_url simple_doc
        aid = "aid=" + simple_doc.attr("aid")
        sta = "sta=" + simple_doc.attr("sta")
        blk = "blk=" + simple_doc.attr("blk")
        params = [aid, sta, blk].join("&")
        domain_name + "/aspsite/unitDetails.aspx?" + params.gsub(/\s/, "%20")
      end

      def retrieve_listing doc, url=nil, opts={}
        listing = {}
        res = get get_listing_url(doc)
        if res.code == "200"
          l_doc = Nokogiri::HTML(res.body).css("#slideBox")
          listing[:title] = l_doc.css(".bldLbl").text.strip
          listing[:url] = get_listing_url doc
          listing[:unit] = l_doc.css(".bldadd").text.split(/APT\s*\#/i).last.strip
          listing[:flag] = get_flag_id("rental")
          l_doc.css(".splitContainer .splitLeft .detail").text.split("\n").each do |de|
            listing[:beds] = de.split(":").last.strip.to_f if de.match(/bed/i)
            listing[:baths] = de.split(":").last.strip.to_f if de.match(/bath/i)
            listing[:price] = de.split(":").last.split('.').first.gsub(/\D+/, "") if de.match(/price/i)
          end
          listing[:description] = l_doc.css(".splitRight .mtext").text.strip
          listing[:amenities] = l_doc.css(".myUL li").to_html.gsub("\n","").split("</li><li>").map do |li|
            li.gsub(/[(\<li\>)(\<\/li\>)]/, "")
          end
          latlng = l_doc.css(".splitLeft a.trueLink").attr("href").value.split("?").last.match(/lat=(.+)\&lng=(.+)/)
          listing[:lat] = latlng[1].strip
          listing[:lng] = latlng[2].strip
          listing[:no_fee] = true
          retrieve_agents(l_doc, listing)
          retrieve_images(l_doc, listing)
          retrieve_broker(l_doc, listing)
        end
        if listing[:agents].first.present?
          listing[:contact_name] = listing[:agents].first[:name]
          listing[:contact_tel] = listing[:agents].first[:tel]
        end
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
        listing
      end

      def retrieve_agents doc, listing
        listing[:agents] = []
        agent = {}
        doc.css(".agentBox").each do |ag|
          agent[:name] = ag.css("#ctl00_ContentPlaceHolder2_Agentsp").text.split(":").last.strip
          agent[:email] = ag.css(".trueLink span").text.strip
          agent[:tel] = ag.css("#ctl00_ContentPlaceHolder2_Phonesp").text.gsub(/\D+/, "")
          agent[:address] = ag.css("#ctl00_ContentPlaceHolder2_Addresssp").to_html.split("<br>").first.gsub(/\<.+\>/, "")
          listing[:agents] << agent
        end
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "S.W. Management LLC.",
          email: "csleasing@swmanagement.com",
          tel: "2125173000",
          website: domain_name,
          zipcode: "10075",
          street_address: "511 East 78th Street",
          introduction: %q{
            S.W. Management is a family-owned and operated Real Estate Management company that began in 1958 with a single, four story walk-up building in the Bronx. From day one, we understood how important it was for an owner to be integrally involved in the day-to-day management of a great building, and the fusion of ownership and management has been a hallmark of the company's success for more than 50 years.
S.W. Management LLC offers high quality properties in desirable locations throughout New York City and Westchester, providing prospective tenants with a rich and varied array of residences from which to choose. Whether you are seeking a starter studio, an airy loft or a luxury residence with family-friendly amenities, S.W. Management is your source for choice, affordability and - most importantly - an owner's commitment to the place you call home.
          }
        }
      end

      def retrieve_images doc, listing
        listing[:images] = []
        doc.css(@listing_image_css).each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc.attr('src').gsub("..", ""))}
        end
      end

    end
  end
end
