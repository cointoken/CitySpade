module Spider
  module NYC
    class Dermotproperties < Spider::NYC::Base
      def initialize
        super
        @simple_listing_css = ".listingresultstitlebar td b .listingresultslink"
      end

      def domain_name
        'http://www.dermotproperties.com'
      end

      def base_url
        domain_name + "/default.asp?f=rental_listings"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        max_id = 3
        (0..max_id).map do |i|
          url = URI.escape(base_url + "&Page=#{i+1}")
          [url, 1]
        end
      end

      def get_listing_url simple_doc
        abs_url simple_doc.attr("href")
      end

      def retrieve_detail(doc, listing)
        l_doc = doc.css("#table1 #table2")
        listing[:title] = l_doc.css("#table11 font").text.split("\r\n\t").first.strip
        listing[:zipcode] = l_doc.css("#table11 font").text.split("\r\n\t").last.strip.match(/(\d+)\,/)[1]
        listing[:flag] = get_flag_id "rental"
        lis = l_doc.css("#table10 tr").text.split("\r\n\t").reject(&:blank?).map(&:strip)
        lis.each_with_index do |li, i|
          listing[:beds] = lis[i-1].strip.to_f if li.match(/bedrooms/i)
          listing[:baths] = lis[i-1].strip.to_f if li.match(/bathrooms/i)
          listing[:sq_ft] = lis[i-1].strip.to_f if li.match(/square/i)
        end
        listing[:price] = l_doc.css("#table5 tr td").text.match(/\$([\d\,]{1,})/)[1].gsub(/\D+/, "")
        listing[:agents] = retrieve_agents(l_doc, listing)
        retrieve_broker doc, listing
        if listing[:agents][0].present?
          listing[:contact_name] = listing[:agents][0][:name]
          listing[:contact_tel] = listing[:agents][0][:mobile_tel]
        end
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
        listing[:description] = l_doc.css("#postingbody p").text.split("Rent").first.to_s.strip
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        lis = doc.css("#table5 tr #table6").text.strip.gsub(/\r\n\t/,"").gsub("\t\t"," ").split("\t").map(&:strip).reject(&:blank?)
        agent = {}
        lis.each do |li|
          agent[:name] = li.split("\r\n").last.strip.split(/\S+@/).first.strip if li.match(/@/)
          agent[:email] = li.match(/(\S+@\S+\.com)/)[1] if li.match(/@/)
          agent[:mobile_tel] = li.gsub(/\D+/, "") if li.match(/phone/i) or li.match(/mobile/i)
        end
        agents << agent
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Dermot Realty Management",
          website: domain_name,
          tel: "2124881770",
          street_address: "729 Seventh Avenue, 15th Floor",
          zipcode: "10019",
          introduction: %q{
            The Dermot Realty Management Company is a full service property management company that owns and operates a portfolio of over 3000 residential rental units and retail property in the New York City and Midwest.
Formed in 1991 as a real estate and management company focused on multi-family sector opportunities, Dermot today is a broad-based, diverse company experienced in all facets of the industry.
From ground-up development and buy & hold strategies to turnaround assignments and adaptive reuse, we have the flexibility to manage any type of project.
          }
        }
      end

      def retrieve_images doc, listing
        listing[:images] = []
        imgdocs = doc.css('#table2 embed')
        if imgdocs.attr("flashvars").present?
          xml_url = abs_url imgdocs.attr("flashvars").value.gsub("xmlfile=","")
          res = get(xml_url)
          if res.code == "200"
            album = Nokogiri::HTML(res.body).css("gallery album")
            path = album.attr("tnpath").value if album.attr("tnpath")
            album.css("img").each do |img|
              if path.present?
                src = path + img.attr("src")
                listing[:images] << {origin_url: URI.escape(src) }
              end
            end
          end
        end
        listing
      end

    end
  end
end
