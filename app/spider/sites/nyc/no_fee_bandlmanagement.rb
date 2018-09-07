module Spider
  module NYC
    class Bandlmanagement < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".searchResultsLists .searchResultsContent .searchResultsButtons li a[title='More Details']"
        @listing_image_css  = ".Left-Section img"
      end

      def domain_name
        'http://www.bandlmanagement.com'
      end

      def base_url(flag = 'rental')
        domain_name + "/SearchProperties.htm"
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def self.enable_urls
        urls = []
        #res = RestClient.get("http://www.bandlmanagement.com/SearchProperties.htm")
        res = RestClient.get("http://www.bandlmanagement.com/Search-NYC-Apartments.htm")
        if res.code.to_s == "200"
          #Nokogiri::HTML(res.body).css(".searchResultsLists .searchResultsContent .searchResultsButtons li a").each_with_index do |doc, i|
            #urls << doc.attr("href") if i % 4 == 0
          #end
          Nokogiri::HTML(res.body).css(".searchResultsButtons li a[title='More Details']").each do |x|
            urls << x['href']
          end
        end
        urls
      end

      def get_listing_url simple_doc
        abs_url simple_doc["href"]
      end

      def listings(options={})
        page_urls.each do |url_opt|
          flag_i = url_opt.last
          url    = url_opt.first
          @logger.info 'get url', url
          res = get(url)
          if res.code == '200'
            Nokogiri::HTML(res.body).css(@simple_listing_css).each do |doc|
              #next if i % 4 != 0
              listing = retrieve_listing(doc, url, options)
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
          else
            []
          end
        end
      end

      def retrieve_listing(doc, url, options)
        listing = {}
        res = get(get_listing_url(doc))
        if res.code == "200"
          l_doc = Nokogiri::HTML(res.body).css(".Property-detail")
          listing[:url] = get_listing_url doc
          listing[:flag] = get_flag_id "rental"
          listing[:title] = l_doc.css("h1").text.split("(").first.strip
          puts listing[:title]
          lis = l_doc.css(".Property-Features li").text.split("\r\n")
          lis.each_with_index do |li, i|
            listing[:raw_neighborhood] = lis[i+1].strip if li.match(/neighborhood/i)
            listing[:unit] = lis[i+1].split('/')[1].strip if li.match(/unit/i)
            listing[:beds] = lis[i+1].to_f if li.match(/Bed/i)
            listing[:baths] = lis[i+1].to_f if li.match(/Bath/i)
            listing[:price] = lis[i+1].gsub(/[\$\,]/,"").to_i if li.match(/Rent/i)
            listing[:amenities] = lis[i+1].split(",").map(&:strip) if li.match(/Amenities/i) && lis[i+1]
            if li.match(/FOR ACCESS CONTACT/i)
              listing[:contact_tel] = lis[i+1].gsub(/\D+/, "")
              listing[:contact_name] = lis[i+1].gsub(/[\d+\-+]/,"").strip
            end
          end
          #if l_doc.css(".Right-Section script")[1].present?
            #js_url = ""
            #l_doc.css(".Right-Section script").to_s.split("</script>").each do |js|
              #js_url = js.match(/(http:\/\/.+GoogleMaps\.js)/)[1] if js.match(/GoogleMaps\.js/i)
            #end
            ##js_res = get js_url
            ##if js_res.code == "200"
              ## listing[:lat] = Nokogiri::HTML(js_res.body).css("p").text.match(/google\.maps\.LatLng\((\S+)\s+(\S+)\)/)[1]
              ## listing[:lng] = Nokogiri::HTML(js_res.body).css("p").text.match(/google\.maps\.LatLng\((\S+)\s+(\S+)\)/)[2]
            ##end
          #end
          # listing[:description] = "no fee."
          retrieve_images(l_doc, listing)
          retrieve_broker(l_doc, listing)
        end
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "B & L Management",
          website: domain_name,
          tel: "2129062800",
          introduction: %q{
            B & L Management Company specializes in the urban development, redevelopment and management of residential mid and high rise properties. The family owned company was founded in 1980 by Benny Caiola and his three sons. Mr. Caiola constructed his first, privately-owned residential building in 1974. That successful property was swiftly followed by several others.
Since its inception, B & L Management has developed approximately thirty residential apartment buildings located throughout Manhattan. The "one man" operation has grown into a fully staffed office which includes two full-time building managers, a rental office, legal and accounting departments, receptionist and clerks. Mr. Caiola and his three sons still lead the business.
The family also owns and operates Rome Construction Company, which is responsible for the construction of all B & L properties. In addition to new con-struction, the Rome team maintains existing properties in the pristine condition that B & L residents enjoy.
Looking ahead, B & L Management is in the planning stages for several new mid and high rise properties. The Caiola family and staff welcome the opportunity to serve the needs of the discerning city dweller and the growing demand for quality urban housing.
          }
        }
      end
    end
  end
end
