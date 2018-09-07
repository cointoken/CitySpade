module Spider
  module WashingtonDC
    class Mrishomes < Spider::WashingtonDC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '.searchResults_col .sr-list-address a'
        @listing_agent_css = "#listingdetail-contactinfo .listed-by-container .maininfo_agentname a"
        @listing_image_css  = "#photo-carousel li img"
        #@listing_callbacks[:image] =-> (img) {
        #}
      end

      def domain_name
        "http://www.mrishomes.com/"
      end

      def base_url
        domain_name + "Include/AJAX/MapSearch/GetListingPins.aspx?searchoverride=c6c651f6-4475-4746-88f7-d4d011743f22&ts=1429673049444&"
      end

      def boroughs_params
        {
          "Criteria/FilterByAddress" => 1,
          "Criteria/Status" => "1,0",
          "Criteria/ListingTypeID" => 1,
          "Criteria/CumulativeDaysOnMarket" => 31,
          "Groups/Group_Location" => 1,
          "Groups/Group_View" => 1,
          "Groups/Group_Exterior" => 1,
          "Groups/Group_Interior" => 1,
          "Groups/Group_Style" => 1,
          "Groups/Group_AirCon" => 1,
          "Groups/Group_Bedroom" => 1,
          "Groups/Group_Dining" => 1,
          "Groups/Group_Fireplace" => 1,
          "Groups/Group_Foundation" => 1,
          "Groups/Group_Room" => 1,
          "Groups/Group_Heat" => 1,
          "Groups/Group_Level" => 1,
          "Groups/Group_OwnershipType" => 1,
          "Groups/Group_Parking" => 1,
          "Groups/Group_Patio" => 1,
          "Groups/Group_Pool" => 1,
          "Groups/Group_Waterfront" => 1,
          "Groups/Group_Foreclosure" => 1,
          "Criteria/LocationJson" => [[{name: "Washington, DC (City)", type: "City",value: "Washington, DC", isNot: false}]],
          "Criteria/SearchMapNELat" => 39.01660813310157,
          "Criteria/SearchMapNELong" => -76.74957275390622,
          "Criteria/SearchMapSWLat" => 38.7761265148239,
          "Criteria/SearchMapSWLong" => -77.26318359374997,
          "Criteria/Zoom" => 11,
          "Criteria/SearchMapStyle" => "r",
          "IgnoreMap" => false,
          "ListingSortID" => 1,
          "view" => "map",
          "first" => 0,
          "Criteria/SearchType" => "map",
          "SearchTab" => "mapsearch-criteria-basicsearch",
          "CLSID" => 0,
          "ResultsPerPage" => 10
        }
      end

      def page_urls(opts={})
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def listings options={}
        (1..options[:pages] || 20).each do |page|
          res = post(base_url, boroughs_params)
          if res.code == "200"
            res_json = JSON.parse(res.body)
            lis = res_json["listingsHtml"]
            doc = Nokogiri::HTML(lis)
            doc.css(@simple_listing_css).each do |simple_doc|
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
        listing[:title] = doc.css("#listingdetail-title-summary .full-address").text.split(",").first.split("#").first.strip
        listing[:unit] = doc.css("#listingdetail-title-summary .full-address").text.split(",").first.split("#").last.strip
        listing[:zipcode] = doc.css("#listingdetail-title-summary .city-state-zip").text.split(",").last.strip
        listing[:description] = doc.css("#listingdetail-description .details-info").text.strip
        doc.css(".details-info-table .details-header-sub").each do |ty|
          listing[:listing_type] = ty.text.split(":").last.strip if ty.text.strip.match(/Property Type\:/i).present?
        end
        doc.css(".details-info-table .details-text-data").each do |de|
          listing[:beds] = de.text.split(":").last.strip.to_f if de.text.match(/bedrooms\:/i)
          listing[:baths] = de.text.split(":").last.strip.to_f if de.text.match(/bathrooms\:/i)
          listing[:sq_ft] = de.text.split(":").last.strip if de.text.match(/Square Feet\:/i)
        end

        amen = []
        %w{listingdetail-interiorfeatures listingdetail-communityfeatures}.each do |lid|
          doc.css("##{lid} .details-info .details-text-data").each do |de|
            fetu = de.text.split(":").last.split(",").map(&:strip)
            amen.concat(fetu) if fetu != "Other" or fetu != "None"
          end
        end
        listing[:amenities] = amen

        listing[:price] = doc.css(".price-container .price").text.gsub(/\D/, "")

        retrieve_agents doc, listing
        retrieve_broker doc, listing
        retrieve_images doc, listing

        if listing[:agents].first.present?
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
        doc.css("#listingdetail-contactinfo .listed-by-container .listed-by-row").each do |li|
          agent = {}
          agent_detail = li.css(".contact-info")
          agent[:name] = agent_detail.css(".listed-by-agentname .maininfo_agentname").text.strip
          agent[:tel] = agent_detail.css(".listed-by-phone").text.strip.gsub(/\D/, "")
          agent[:email] = agent_detail.css(".listed-by-email").text.strip
          agents << agent
        end
        listing[:agents] = agents
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Metropolitan Regional Information Systems, Inc.",
          street_address: "9707 Key West Ave",
          email: "privacy@MRIS.net",
          #tel: "",
          website: domain_name,
          zipcode: "20850",
          introduction: %q{
            There’s only one home search website serving the Mid-Atlantic that features every listing in the region, available in real time. That’s MRIShomes.com, powered by the Multiple Listing Service (MLS); it’s the only website you’ll need to explore all your home listings all in one place. Get the most accurate listing information, straight from the source, updated around the clock. MRIShomes is the only destination you’ll need to find your dream home, for sale or rental. You can even get matched with the right real estate professional to assist you every step of the way. Why not get started now? MRIShomes currently services Virginia, Maryland, West Virginia, Washington, D.C., Delaware and Pennsylvania.
          }
        }
      end

      def retrieve_images doc, listing
        listing[:images] = []
        imgdocs = doc.css(@listing_image_css)
        imgdocs.each do |img|
          listing[:images] << {origin_url: img.attr("src") }
        end
        listing
      end

    end
  end
end
