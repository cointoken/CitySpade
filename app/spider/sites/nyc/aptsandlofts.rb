module Spider
  module NYC
    class Aptsandlofts < Spider::NYC::Base
      def initialize(opts = {accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                             user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.114 Safari/537.36',
                             accept_cookie: true})
        super
        @simple_listing_css = '#listings .list .location strong a'
        @listing_image_css = "#property-photos .slides-wrap img"
        @listing_callbacks[:image] = ->(img){
          img['src'].sub(/thumb|normal/i, 'original').remove(/\?\d+/)
        }
      end

      def domain_name
        "http://www.aptsandlofts.com/"
      end

      def page_urls(opts={})
        opts[:flag] = %w{rent sale}
        urls = []
        opts[:flag].each do |flag|
          flag_i = get_flag_id(flag)
          if flag_i == 1
            url = "http://www.aptsandlofts.com/rentals/brooklyn-queens-apartments"
            re_url = get_redirect_to_url(flag, url)
            30.times do |t|
              urls << [re_url + "?page=#{t+1}", flag_i]
            end
          else
            url = "http://www.aptsandlofts.com/sales/brooklyn-queens-real-estate"
            re_url = get_redirect_to_url(flag, url)
            5.times do |t|
              urls << [re_url + "?page=#{t+1}", flag_i]
            end
          end
        end
        urls
      end

      def get_redirect_to_url(flag, url)
        resp = Net::HTTP.get_response(URI(url))
        csrf_token = Nokogiri::HTML(resp.body).css("meta[name=csrf-token]").first["content"]
        post(abs_url(url), init_params(flag, {authenticity_token: csrf_token}))
        abs_url redirect_to.request_uri
      end

      def init_params(flag, opts)
        if flag == 'sale'
          {
            commit: "Search",
            'utf8' => '✓',
            'sale_query[bedrooms]' => '',
            'sale_query[master_property_category_id]' => '',
            'sale_query[max_price]' => '',
            'sale_query[amenities][]'=>''
          }.merge! opts
        else
          {
            commit: "Search",
            'utf8' => '✓',
            'rental_query[bedrooms]' => '',
            'rental_query[master_property_category_id]' => '',
            'rental_query[max_price]' => '',
            'rental_query[amenities][]'=>''
          }.merge! opts
        end
      end

      def get_listing_url(simple_doc)
        abs_url(simple_doc["href"]) # + ".html"
      end

      def retrieve_detail(doc, listing)
        tls = doc.css("#listing-header h1")[0].text.split(",")
        listing[:title] = tls.first
        listing[:unit] = listing[:title].split(' Unit ').last if listing[:title].include? ' Unit '
        listing[:zipcode] = tls.select{|s| s =~ /\d{5}/}.first
        listing[:city_name] = tls[1] if tls.size == 3
        alpha = doc.css("#listing-specs .alpha").to_html.split("<dt").map do |html|
          html.remove(/class=\".+\"\>/).remove(/\<dl.+\>/).remove("<dd>").remove("</dd>").
            remove("<strong>").remove("</strong>").remove("<dt>").remove("<dl>").remove("</dl>").
            remove("<dl").remove("<i>").remove("<i").remove("</i>").remove("</dt>")
        end
        alpha = alpha.map do |al|
          al.split("\n").reject(&:blank?)
        end.drop(1)
        i = 0
        while listing[:beds].blank? && i < 2
          alpha[i].each do |al|
            beds = al.match(/Bedroom\(s\):(.+)/)
            baths = al.match(/Bathroom\(s\):(.+)/)
            sq_ft = al.match(/Square Feet:(.+)/)
            listing[:beds] = beds[1].strip unless beds.blank?
            listing[:baths] = baths[1].strip unless baths.blank?
            listing[:sq_ft] = sq_ft[1].match(/approx(.+)square/)[1].strip unless sq_ft.blank?
          end
          i += 1
        end
        amenities_index = 1
        alpha.each_with_index{ |al, index| amenities_index = index if al[0].match(/Amenities/) }
        listing[:amenities] = alpha[amenities_index].drop(1).map(&:strip) if alpha[1].length > 1
        # listing[:listing_type] = alpha[2][1].try(:strip)

        zip = doc.css("#listing-header h1").text.match(/(\d+)\z/)
        listing[:zipcode] = zip[1].try(:strip) unless zip.blank?
        listing[:neighborhood_name] = doc.css("#listing-header .unicode").text.match(/\# \d+(.+)\, \$/)[1].try(:strip)

        omega = doc.css("#listing-specs .omega").to_html.split("\n").map do |html|
          html.remove(/\<p.+\>/).remove("</p>").remove(/class=\".+\"\>/).remove(/\<dl.+\>/).
            remove("<dd>").remove("</dd>").remove("<strong>").remove("</strong>").remove("<dt>").
            remove("<dl>").remove("</dl>").remove("<dl").remove("<i>").remove("</i>").
            remove("</dt>").remove(/\<img.+\>/).remove(/\<a.+\<\/a\>/).remove("<dt")
        end.drop(1).reject(&:blank?).map(&:strip)
        omega.each do |omg|
          rent = omg.match(/Rent:(.+)/)
          sale = omg.match(/Price:(.+)/)
          zip = omg.match(/Zip: (\d+)/)
          listing[:price] = rent[1] unless rent.blank?
          listing[:price] = sale[1] unless sale.blank?
          listing[:price].gsub!(/[\$\,]/, "").try(:strip!) unless listing[:price].blank?
        end
        listing[:contact_name] = doc.css(".contact li strong").children[0].try(:text).try(:strip)
        office_tel = doc.css(".contact li").text.split("\n").reject(&:blank?).map(&:strip).select{|tel| tel.match(/O:(.+)/) }
        listing[:contact_tel] = office_tel[0].match(/O:(.+)/)[1].strip.gsub(/\-/, "") unless office_tel.blank?
        listing[:description] = Nokogiri::HTML(doc.css("#main-content p").to_html.split("<p class=\"tophat\"></p>")[1]).css('p').map{|s| s.text.strip}.join("\n")
        # remove("<p>").remove("</p>").remove("<br>").remove("<b>").remove("</b>").strip.gsub(/\t{3,}/, "\t\t")
        latlng = doc.css("script").text.match(/\\\"lat\\\":\\\"(.+)\\\"\,\\\"lng\\\":\\\"(.+)\\\"\,\\\"html/)
        if latlng
          listing[:lat] = latlng[1]
          listing[:lng] = latlng[2]
        else
          listing = {}
          return
        end
        ## 获取 broker 和 agent 顺序不能变。判断agent 是否归属 aptsandlofts
        retrieve_agent doc, listing
        if listing[:agents].blank? || listing[:agents].first[:email].include?('@aptsandlofts.com')
          retrieve_broker listing
        end
        listing
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'Apts and Lofts',
          website: 'http://www.aptsandlofts.com/',
          state: 'NY'
        }
      end

      def retrieve_agent doc, listing
        listing[:agents] = []
        doc.css(".agent").each do |html|
          agent = {}
          agent[:name] = html.css('ul.contact li:first strong').text.strip
          agent[:address]  = html.css("ul.contact li")[1].try(:text).try(:strip).try(:gsub, /\s?\n\s+/, ', ')
          agent[:email]  = html.css(".over").text.strip
          tels = html.css("ul.contact li")[2]
          if tels.present?
            agent[:tel] = tels.children.first.text.strip.remove(/\D/)
          end
          link = html.css("a").first
          if link
            agent[:website] = abs_url link['href']
            img = link.css('img').first
            if img
              agent[:origin_url] = img['src'].split('?').first unless img['src'].include? 'aptslofts_logo'
            end
          end
          listing[:agents] << agent
        end
        listing
      end
    end
  end
end
