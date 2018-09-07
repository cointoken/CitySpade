module Spider
  module Boston
    class Properrg < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".ygl_listing .ygl_img a"
        @listing_image_css = ".ygl_photo_thumbs li img"
        @listing_callbacks = {
          image: ->(img){
            img['src'] if img['src'] !~ /nophoto/
          }
        }
      end

      def domain_name
        "http://www.properrg.com/"
      end

      def page_urls(opts={})
        urls = []
        opts[:flags] = %w{rents sales}
        opts[:flags].each_with_index do |flag, index|
          flag_i = get_flag_id(flag)
          if flag_i == 0
            60.times do |num|
              urls << [abs_url(
                "buyers/?city_neighborhood=Boston&beds=&max_price=&search_rentals.x=92&search_rentals.y=44&search_rentals=Search&pageIndex=#{num + 1}&pageCount=10"
              ), flag_i]
            end
          else
            90.times do |num|
              urls << [abs_url(
                "renters/?sort=AVAILABLE_DATE&city_neighborhood=Boston&beds=&max_rent=&search_rentals.x=51&search_rentals.y=33&search_rentals=Search&pageIndex=#{num + 1}&pageCount=10"
              ), flag_i]
            end
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc["href"]
      end

      def retrieve_detail(doc, listing)
        if listing[:flag] == 1
          listing[:price] = doc.css(".detDescBox")[0].css("div div div")[0].css("span").text.gsub(/\D/, "") unless doc.css(".detDescBox")[0].blank?
          listing[:beds] = doc.css(".detDescBox")[0].css("div div div")[1].css("span").
            text.gsub(/\s/, "").split(".").collect{|el| el.gsub(/\D/, "")}.join(".") unless doc.css(".detDescBox")[0].blank? || doc.css(".detDescBox")[0].css("div div div")[1].blank?
          listing[:baths] = doc.css(".detDescBox")[0].css("div div div")[2].css("span").
            text.gsub(/\s/, "").split(".").collect{|el| el.gsub(/\D/, "")}.join(".") unless doc.css(".detDescBox")[0].blank? || doc.css(".detDescBox")[0].css("div div div")[2].blank?
        else
          listing[:price] = doc.css(".ygl_detail_summary tr")[0].css("td")[1].text unless doc.css(".ygl_detail_summary tr")[0].css("td")[1].blank?
          listing[:beds] = doc.css(".ygl_detail_summary tr")[1].css("td")[0].
            text.gsub(/\s/, "").split(",").collect{|el| el.gsub(/\D/, "")}.join(".") unless doc.css(".ygl_detail_summary tr")[1].blank?
          listing[:baths] = doc.css(".ygl_detail_summary tr")[1].css("td")[1].
            text.gsub(/\s/, "").split(",").collect{|el| el.gsub(/\D/, "")}.join(".") unless doc.css(".ygl_detail_summary tr")[1].blank? || doc.css(".ygl_detail_summary tr")[1].css("td")[1].blank?
          listing[:sq_ft] = doc.css(".ygl_detail_summary tr")[2].css("td")[0].text.gsub(/\D/, "") unless doc.css(".ygl_detail_summary tr")[2].blank?
        end
        # listing[:title] = doc.css('meta[property="street_address"]').first['content']
        listing[:zipcode] = doc.css('meta[property="postal_code"]').first['content']
        latlng = doc.css("#ygl_tabpanel_map script").text.match(/maps\.LatLng\((.+)\)/)
        if latlng
          latlng = latlng[1]
        else
          listing = {}
          return
        end
        listing[:lat] = latlng.split(",")[0]
        listing[:lng] = latlng.split(",")[1].gsub(/\s/, "")

        # listing[:lat] = doc.css('meta[property="place:location:latitude"]').first['content']
        # listing[:lng] = doc.css('meta[property="place:location:longitude"]').first['content']
        listing[:contact_name] = "PROPER"
        listing[:contact_tel] = "6177563029"
        listing[:description] = doc.css(".ygl_detail_desc p").text
        listing[:amenities] = doc.css('table.ygl_detail_featurelist td').map{|s| s.text.strip}
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        agent = {}
        if doc.css("detColRight div div")[2].present?
          agent[:name] = doc.css(".detColRight div div")[2].css("span").text.strip
          agent[:tel] = doc.css(".detColRight div div")[2].css("div").text.gsub(/\D/, "")
        end
        agent[:origin_url] = doc.css(".listAgentPic img").attr("src").value if doc.css(".listAgentPic img").present?
        agents << agent
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Proper Realty Group",
          tel: "6177563029",
          email: "info@properrealtygroup.com",
          street_address: "1298A Commonwealth Avenue.
Allston",
          zipcode: "02134",
          website: domain_name,
          introduction: "Proper Realty Group is a modern, full-service real estate agency committed to providing our clients with exceptional service and insight into Boston area communities. Proper Realty Group employs the latest technology to provide clients 24-hour online access and real time property updates.  We understand that real estate is about more than property. It’s about our clients–whether they’re landlords, tenants, buyers, or sellers–and really getting to know them, their type of lifestyle, and future goals in order to find the perfect environment to fit those needs.

With a large network, outstanding client and community relationships, and real estate expertise, we’ve built a loyal following of clients. Whether you are searching for a hip apartment, your first home, a smart investment deal or someone to help manage your property, Proper can help simplify the process. Let Proper show you the possibilities."
        }
      end
    end
  end
end
