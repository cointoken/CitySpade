module Spider
  module Chicago
    class Diversesolutions < Spider::Chicago::Base
      def initialize(accept_cookie: true)
        super
      end

      def domain_name
        "http://www.thechicagomls.com/"
      end

      def post_listings_url flag
        url = "http://idx.diversesolutions.com/api/results?requester.AccountID=2674&requester.ApplicationProfile=dsSearchAgentV3&directive.SortOrders%5B0%5D.Column=DateAdded&directive.SortOrders%5B0%5D.Direction=DESC&directive.ResultsPerPage=250&responseDirective.IncludeMetadata=true&query.SearchSetupID=17&query.LinkID=69722&query.DaysOnMarketMin=8&query.LatitudeMin=41.60466108823081&query.LongitudeMin=-88.2861328125&query.LatitudeMax=42.19444265006989&query.LongitudeMax=-87.15866088867188&query.PropertySearchID=5525130"
        if flag == "rent"
          url + "&query.PropertyTypes%5B0%5D=89"
        else
          url + "&query.PropertyTypes%5B5%5D=118&query.PropertyTypes%5B4%5D=117&query.PropertyTypes%5B3%5D=115&query.PropertyTypes%5B2%5D=116&query.PropertyTypes%5B1%5D=86"
        end
      end

      def post_details_url listing_id
        "http://idx.diversesolutions.com/api/details?requester.AccountID=2674&requester.ApplicationProfile=dsSearchAgentV3&responseDirective.IncludeDisclaimer=false&query.SearchSetupID=17&query.ListingStatuses=15&query.PropertyID=#{listing_id}&query.MlsNumber=08890085"
      end

      def page_urls(opts={})
        urls = []
        %w{rent sale}.each do |type|
          urls << [post_listings_url(type), get_flag_id(type)]
        end
        urls
      end

      def listings(opts={})
        results= []
        page_urls(opts).each do |url_opt|
          flag_i = url_opt[1] || 1
          url    = url_opt.first
          @logger.info 'get', url
          res = get(url)
          if res.code == '200'
            lls = JSON.parse(res.body)["Results"]
            lls.each do |ll|
              del_url = post_details_url(ll["PropertyID"])
              del_res = get(del_url)
              if del_res.code == "200"
                simple_doc = JSON.parse(del_res.body)["PropertyDetail"]["Normalized"]
                listing = retrieve_detail(simple_doc, flag_i)
                listing[:url] = del_url
                next unless listing
                next if !((listing[:title] || listing[:street_address]) || (listing[:lat] && listing[:lng]))
                listing[:city_name] ||= @city_name
                listing[:state_name] ||= @state_name
                check_title(listing)
                listing = check_flag(listing)
                next if listing.blank?
                listings = [listing].flatten
                results << listings
                if block_given?
                  @logger.info listing
                  listings.each do |l|
                    yield l
                  end
                else
                  @logger.info listing
                  listing
                end
              end
            end
          else
            []
          end
        end
        results
      end

      def retrieve_detail doc, listing
        listing = {}
        listing[:title] = doc["Address"].split(",").first.strip
        listing[:zipcode] = doc["Zip"].strip
        listing[:unit] = doc["Address"].split(/Unit Number/i).last.strip if doc["Address"].match(/Unit Number/i).present?
        listing[:street_address] = doc["Address"].split(",").first.strip
        listing[:price] = doc["Price"]
        listing[:beds] = doc["Beds"].to_f
        listing[:baths] = doc["BathsTotal"].to_f
        listing[:sq_ft] = doc["LotSqFt"].to_f + doc["ImprovedSqFt"].to_f
        listing[:description] = doc["Description"].strip if doc["Description"].present?
        listing[:city_name] = doc["City"].strip
        listing[:state_name] = doc["State"].strip
        listing[:lat] = doc["Latitude"]
        listing[:lng] = doc["Longitude"]
        listing[:flag] = 1 unless doc["IsRental"] == "unknow"

        #Above 15000 would be considered as 
        if listing[:price] > 15000
          listing[:flag] = 0
        end
        
        retrieve_agents doc, listing
        retrieve_images doc, listing
        retrieve_broker doc, listing

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
          # agent = {
          #   name: doc["ListingAgentName"],
          #   tel: doc[""]
          # }
          # agents << agent
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "The ChicagoHome Brokerage Network",
          tel: "7734720200",
          # email: "",
          website: domain_name,
          street_address: "548 W. Webster",
          zipcode: "60614",
          introduction: %q{
            Our goal is to make it Easy to Search + Easy to Find + Easy to Visit the properties you have selected. We are local Realtors, NOT a Lead Generation or an Advertising Company - so if you have a question, you get answers by true LOCAL professionals. Home buying should be fun - we're all about Fun & Top Notch Service!
          }
        }
      end

      def retrieve_images doc, listing
        listing[:images] = []
        uri_base = doc["PhotoUriBase"]
        imgs_count = doc["PhotoCount"]
        imgs_count.times do |i|
          listing[:images] << { origin_url: uri_base + i.to_s + "-full.jpg"}
        end
      end

    end
  end
end
