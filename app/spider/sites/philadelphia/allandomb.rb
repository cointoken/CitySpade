module Spider
  module Philadelphia
    class Allandomb < Spider::Philadelphia::Base
      def initialize(accept_cookies: true)
        super																			            # Site::Base#initialize
        @simple_listing_css = "#prop .photo a"								# listings' links
        @listing_image_css = "#detailsRight #info span img"	  # listing imgs
      end

      def domain_name
        'http://www.allandomb.com/'
      end

      # 存放每个页面的租房信息链接
      def page_urls(opts)
        urls = []
        opts[:flags] ||= %w{rent sale}
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)							# rent:1 sale:0
          flag = (flag == 'rent' ? 11 : 5)
          30.times do |t|
            listings_url = abs_url("properties?type=#{flag}&page=#{t+1}&search=&price=ASC&bed=&locations=&building=")
            urls << [listings_url, flag_i]
          end
        end
        urls
      end

      # 进入租房信息具体页面，获取详细信息
      # doc:为Nokogiri的到具体房信息listing的body对象
      # listing: 为{ flag, uri }
      def retrieve_detail(doc, listing)
        listing[:title] = doc.css("#row4 #c2 span.blueCaps div:last").text.strip
        right_details = doc.css("#detailsRight #bar #info")
        listing[:listing_type] = right_details[1].css("#right").children[6].text
        listing[:price] = decorate_price(right_details[1].css("#right").children[0].text)
        listing[:beds] = right_details[2].css("#right").children[2].text
        listing[:baths] = decorate_baths(right_details[2].css("#right").children[4].text)
        listing[:sq_ft] = right_details[2].css("#right").children[6].text
        listing[:amenities] = right_details[3].text.split("\n")
        children = doc.css("#detailsLeft #row7 #c2").children
        listing[:description] = dispose_str(children)
        listing[:contact_name] = 'Allan Domb'
        listing[:contact_tel]  = '2155451500'
        retrieve_broker(doc, listing)
        listing
      end


      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "AllanDombRealEstate",
          email: "domb@allandomb.com",
          tel: "2155451500",
          street_address: "1845 Walnut Street Suite 2200",
          zipcode: "19103",
          website: domain_name,
          introduction: "Twenty years ago, condominiums were almost nonexistent in the Delaware Valley. Today, one out of every four home sales is a high-rise or garden condominium. Condominiums are not a new form of housing, but one that is over 300 years old. Recently, condominiums have again become a very popular alternative to single family homes.

The reasons are very simple:
Features
Security
Affordability
Maintenance",
        }
      end

      # Listings中每个住房信息的链接uri
      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      # 这个网站的图片也坑爹有些有空格，必须覆写
      def retrieve_images(doc, listing, opt={})
        listing[:images] = []
        imgs = doc.css(@listing_image_css)
        if imgs.blank?
          unless doc.css("#detailsLeft #row5 img").blank?
            img_src = correct_url(doc.css("#detailsLeft #row5 img")[0]['src'])
            origin_url = abs_url(img_src)
            listing[:images] << {origin_url: origin_url} if origin_url.present?
          end
        else
          imgs.each do |img|
            img_src = correct_url(img['src'])
            origin_url = abs_url(img_src)
            listing[:images] << {origin_url: origin_url} if origin_url.present?
          end
        end
        listing
      end

      protected
      def decorate_price(str)
        str.gsub(/\..+$/, '').gsub(/\D/, '')
      end

      def decorate_baths(str)
        if str.strip =~ /^\d+$/
          str.strip
        else
          return 0 if str.blank?
          num = 0
          nums = str.split(/\s/).select{|s| s =~ /^\d+$/}
          num = nums[0].to_i  + 0.5
          num
        end
      end
      def dispose_str(children)
        str = ''
        return '' if children.blank?
        children.each do |child|
          if child.text.strip == 'Unit Information'
            str << child.text.strip << "\n"
          elsif child.name == 'span' && child['class'] == 'blueCaps' && str.present?
            break
          else
            if child.text.strip.present?
              str << child.text.strip << "\n"
            end
          end
        end
        str
      end

      def correct_url(url)
        url.gsub(/\s+/, "%20").gsub(/\[/,"%5b").gsub(/\]/, "%5d")
      end
    end
  end
end
