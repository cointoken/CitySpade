module Spider
  module LA
    class Themls < Spider::LA::Base
      def initialize(accept_cookie: true)
        @simple_listing_css = "#MainContent_dtListView ul li.Address .MyFavContainer a"
        super
      end

      def domain_name
        "http://www.themls.com/"
      end

      def base_url
        "http://guests.themls.com/GuestJSONWeb.asmx/GetFavoritesMLSNums"
      end

      def boroughs_params(page_num)
        {
          "ctl00$MainContent$AjaxScriptManager1" => "ctl00$MainContent$updPanel|ctl00$MainContent$top#{page_num}",
          "__EVENTTARGET" => "ctl00$MainContent$top1",
          "ctl00$MainContent$SmartSearch1$txtSearchBox" => "Los Angeles",
          "ctl00$MainContent$SmartSearch1$chklstStatus$0" => 5,
          "ctl00$MainContent$SmartSearch1$chklstStatus$1" => 30,
          "ctl00$MainContent$SmartSearch1$chklstStatus$2" => 10,
          "ctl00$MainContent$SmartSearch1$chklstPropType$0" => 0,
          "ctl00$MainContent$SmartSearch1$chklstPropType$1" => 1,
          "ctl00$MainContent$SmartSearch1$chklstPropType$2" => 2,
          "ctl00$MainContent$SmartSearch1$chklstPropType$3" => 3,
          "ctl00$MainContent$SmartSearch1$chklstPropType$4" => 4,
          "ctl00$MainContent$SmartSearch1$chklstPropType$5" => 11,
          "ctl00$MainContent$SmartSearch1$rdlSQFrom" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlSQTo" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlYearFrom" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlYearTo" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlSoldPrice" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlLotSize" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlBed" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlBath" =>"[00]",
          "ctl00$MainContent$SmartSearch1$rdlParking" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlDaysInStatus" => "[00]",
          "ctl00$MainContent$SmartSearch1$rdlPriceCriteria" => 1,
          "ctl00$MainContent$SmartSearch1$ddlCounties" => 5,
          "ctl00$MainContent$ddlSort" => 0
        }
      end

      def get_listing_url(simple_doc)
        abs_url(simple_doc["href"]) # + ".html"
      end

      def listings options={}
        (1..options[:pages] || 20).each do |page|
          res = post(base_url, boroughs_params(page))
          if res.code == "200"
            html = Nokogiri::HTML(res.body)
            html.css(@simple_listing_css).each do |simple_doc|
              listing = retrieve_listing(simple_doc)
              listing[:city_name] ||= @city_name
              listing[:state_name] ||= @state_name
              next unless listing

              check_title listing
              if block_given?
                @logger.info listing
                yield(listing)
              else
                listing
              end
            end
          end
        end
      end

      def retrieve_detail doc, listing
        listing[:flag] = 1
        listing[:title] = doc.css('.Address #lblAddr').text.strip
        listing[:street_address] = doc.css('.Address #lblAddr').text.strip
        listing[:zipcode] = doc.css(".CityName #lblzp").text.strip
        detail = doc.css(".panel .DataLeft li")
        detail.each do |de|
          listing[:sq_ft] = de.text.split(":").last.strip if de.text.match(/Sq Ft\:/i)
          listing[:beds] = de.text.split(":").last.to_f if de.text.match(/Beds\:/i)
          listing[:baths] = de.text.split(":").last.remove(/\([\d\,]+\)/).to_f if de.text.match(/Baths\:/i)
          listing[:listing_type] = de.text.split(":").last.strip if de.text.match(/Property Type\:/i)
          listing[:amenities] = de.css(".DataAmenites .DataAmenitiesInfo").text.split(",").map(&:strip)  if de.css(".DataAmenities .DataAmenitiesInfo").text.strip != "N/A"
          retrieve_open_houses(de, listing) if de.text.match(/Open House/i)
        end
        listing[:description] = doc.css(".RemarksSection .Content").text.strip
        listing[:price] = doc.css(".ListingPrice #MainContent_frmDetails_lblLPValue").text.gsub(/\D/, "")

        retrieve_agents doc, listing
        retrieve_broker doc, listing
        retrieve_images doc, listing

        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "The MLS™ Officers & Directors",
          street_address: "8350 Wilshire Blvd. 1st Floor",
          zipcode: "90211",
          tel: "3103581100",
          # email: "",
          website: domain_name,
          introduction: %q{
            The MLS™ Notice/Fair Housing:
Properties & rentals in this MLS are subject to the Fair Housing Act. It is illegal to advertise any preference, limitation, or discrimination because of race, color, religion, sex, handicap, familial status, or national origin, or intention to make any such preference, limitation or discrimination. This MLS will not knowingly accept any advertising that is in violation of the law. All dwellings advertised are available on an equal opportunity basis. The information provided by Combined LA/Westside Multiple Listing Service, Inc. is intended for the sole and exclusive use of its Participants and Subscribers. The information provided herein is copyrighted in 2015 by Combined LA/Westside Multiple Listing Service, Inc., Los Angeles, California. Any unauthorized use or disclosure to persons or entities other than to authorized Participants and Subscribers is strictly prohibited and a violation of the copyright.
          }
        }
      end

      def retrieve_agents doc, listing
        doc.css(".AgentData li").each do |ag|
          agent = {}
          ag.css("ul li").each do |li|
            agent[:name] = li.css(".right").text.split("|").first.strip if li.css(".left").text.match(/Name\:/i)
            agent[:email] = li.css(".right").attr("onclick").match(/ShowEmailForm\(\'(.+)\'\)/)[1]
            agent[:tel] = li.css(".right").text.gsub(/\D/, "") if li.css(".left").text.match(/Phone\:/i)
            agent[:mobile] = li.css(".right").text.gsub(/\D/, "") if li.css('.left').text.match(/Cell\:/i)
            agent[:office_tel] = li.css(".right").text.gsub(/\D/, "") if li.css(".left").text.match(/Office Phone\:/i)
          end
          listing[:agents] << agent unless agent[:name] == "N/A"
        end
      end

      def retrieve_images doc, listing
        listing[:images] = []
        doc.css("#MainContent_frmDetails_dtlstGallery td a").each do |img_a|
          listing[:images] << {origin_url: img_a.attr("href")}
        end
      end

      def retrieve_open_houses doc, listing
        listing[:open_houses] = []
        doc.css(".RInfo").text.split(",").each do |oh|
          open_date = Date.parse oh.split(" ").first
          begin_time = Time.parse oh.split(" ").last.split("-").first
          end_time = Time.parse oh.split(" ").last.split("-").last
          listing[:open_houses] << {open_date: open_date, begin_time: begin_time, end_time: end_time}
        end
      end

    end
  end
end
