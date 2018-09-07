module Spider
  module NYC
    class Harlingtonllc < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".bldg-item h2 a"
      end

      def domain_name
        'http://www.harlingtonllc.com/'
      end

      def page_urls(opts)
        [['http://www.harlingtonllc.com/residential?rentmin=&rentmax=&openhouse=false', 1]]
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        title = doc.css('#body-itself .main h1').first
        listing[:title] = title.children.first.text.strip
        neigh = title.css('span').text
        unless neigh.include?('New York')
          listing[:city_name] = neigh.split(/\s/).first
        end
        if listing[:title] !~ /\d+\s/
          listing[:is_full_address] = false
        else
          listing[:is_full_address] = true
        end
        boxes = doc.css('#body-itself .main .box')
        if boxes.first.css('h5').text.include? 'Agent'
          agent =boxes.first
          # listing[:broker_name] = agent.css('div>div').first.text.strip
          listing[:contact_name] = agent.css('div>div').last.text.split(/\d/).first.strip.remove(/^\W+/)
          listing[:contact_tel] = agent.css('div>div').last.text.remove(/\D/)
        end
        listing[:description] = doc.css('#body-itself .main>div')[1].text.strip
        listing[:amenities] = doc.css('#body-itself .main>div.amenity-container .amenity').map{|s| s.text.strip}.reject(&:blank?)
        listing[:no_fee] = true
        listing[:listings] = []
        doc.css("#body-itself .main .avl").each do |ldoc|
          br_text = ldoc.css('>div').first.text
          next unless br_text.include? 'BR'
          l = {}
          trs = ldoc.css('tr')
          tds = trs[0].css('td')
          l[:unit] = tds[0].text.remove(/Apt|\#/i).strip
          l[:beds] = tds[1].text.to_f
          l[:baths] = tds[2].text.to_f
          l[:price] = tds[3].text.remove(/\D/)
          retrieve_images_for_each_listing ldoc, l
          l[:description] = trs[2].text.strip + "\n#{listing[:description]}"
          l[:amenities] = ldoc.css('.amenity-container .amenity').map{|s| s.text.strip}.reject(&:blank?) + listing[:amenities]
          l[:url] = listing[:url] + "##{l[:unit]}-#{l[:beds]}".remove(/\s/)
          listing[:listings] << l
        end
        retrieve_open_houses(doc, listing)
        listing
      end

      def retrieve_open_houses doc, listing
        open_houses = []
        doc.css("div .box .box div").text.split("\r\n").reject(&:blank?).map(&:strip).each do |oh|
          if oh.match(/[\d\:]+\s*[A-z]{2}\s*\-[\d\:]+\s*[A-z]{2}/)
            open_date = Date.parse(oh.split(",").first.strip)
            begin_time = Time.parse(oh.split(",").last.split("-").first.strip)
            end_time = Time.parse(oh.split(",").last.split("-").last.strip)
            open_houses << {open_date: open_date, begin_time: begin_time, end_time: end_time}
          end
        end
        listing[:open_houses] = open_houses if open_houses.present?
      end

      # rewrite retrieve_images
      def retrieve_images doc, listing, opt={}
        {}
        listing
      end

      def retrieve_images_for_each_listing doc, listing
        listing[:images] ||= []
        doc.css('.fancybox.space-pic').each do |img|
          listing[:images] << {origin_url: abs_url(URI.escape(img['href'].split('?').first))}
        end
        listing
      end
    end
  end
end
