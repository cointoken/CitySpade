module Spider
  module NYC
    class Yucoinc0 < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#content #subContent table tr td strong a"
      end

      def domain_name
        "http://www.yucoinc.com"
      end

      def base_url
        domain_name + "/availabilities/?pCategoryId=1"
      end

      private :domain_name, :base_url

      def page_urls opt={}
        max_id = 2
        (0...max_id).map do |i|
          [base_url + "&pTRows=8&pPNum=#{i}", 1]
        end
      end

      def get_listing_url simple_doc
        domain_name + "/availabilities/" + simple_doc["href"]
      end

      def retrieve_listing doc, url=nil, options
        listing = {}
        res = get(get_listing_url(doc))
        if res.code == "200"
          listing[:url] = get_listing_url doc
          l_doc = Nokogiri::HTML(res.body).css("#content #subContent")
          listing[:flag] = get_flag_id("rental")
          listing[:title] = l_doc.css("#heading tr td h1").text.strip
          listing[:raw_neighborhood] = l_doc.css("#heading tr td p").last.text.split(",").first.strip
          l_doc.css("table tr td table tr").each do |tr|
            listing[:unit] = tr.text.strip.split("\n")[1].strip if tr.text.match(/Unit/i)
            listing[:beds] = tr.text.strip.split("\n")[1].strip.to_f if tr.text.match(/size/i)
            listing[:price] = tr.text.strip.split("\n")[1].gsub(/\D+/, "") if tr.text.match(/rent/i)
          end
          listing[:description] = l_doc.css("table tr td p").last.text.strip + "No Fee."
          retrieve_images(l_doc, listing)
          retrieve_broker(l_doc, listing)
          listing[:contact_name] = listing[:broker][:name]
          listing[:contact_tel] = listing[:broker][:tel]
        end
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Yuco Real Estate Company, Inc.",
          website: domain_name,
          email: " rentals@yucoinc.com",
          tel: "2129942246",
          street_address: "200 Park Avenue, 11th Floor",
          zipcode: "10166",
          introduction: %q{
Yuco Real Estate Company, Inc. and Yuco Management, Inc. are part of a real estate development and management organization which has been active in New York City since 1969.
Yuco Real Estate Company and its principals have successfully completed numerous commercial and residential projects throughout New York City. We are able to professionally and expeditiously carry out all aspects of the development process from acquisition, financing, municipal approvals, design and construction to marketing, leasing and sales while maintaining strict quality control over the entire design and construction process, thereby ensuring that each of our projects is completed to exacting standards. We have completed the new construction or substantial rehabilitation of more than sixty buildings.  Our design and construction work are performed by our affiliated architectural/engineering firm and general contracting company.
Our projects range from repositioning and entirely renovating a 112,000 square foot NoHo/SoHo office building with retail space, to constructing a 95-unit development of spacious, affordable housing in West Harlem, to converting two prime, elevatored properties in Brooklyn Heights, directly off the promenade, into luxury rental apartments.
Yuco Management manages commercial and residential properties throughout New York City. As a professional and hands-on building management company, all administrative, maintenance and repair issues are resolved in a timely manner. Our highly trained office and building personnel and our use of sophisticated property management and accounting software ensure that our properties are continuously maintained and operated to the highest standards.  We offer quality office and retail space and both affordable and market rate residential housing in convenient neighborhoods throughout New York City.
The first class manner in which our properties are built and maintained has enabled us to attract discerning local, as well as, large public corporations as tenants. Our philosophy of only making prudent, well-timed investments, quality construction and design and meticulous attention to detail and service comprise the foundation on which our organization was founded many years ago.
          }
        }
      end

      def retrieve_images doc, listing
        listing[:images] = []
        doc.css("table tr td a").each do |imgdoc|
          listing[:images] << { origin_url: domain_name + "/availabilities/" + imgdoc.attr("href")}
        end
      end

    end
  end
end
