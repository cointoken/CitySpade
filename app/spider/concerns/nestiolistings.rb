module Spider
  module Sites
    module Nestiolistings
      ## Nestiolistings server common code
      def listings(opts={})
        results = []
        if opts[:return_attrs].present?
          results ={opts[:return_attrs] => []} if Symbol === opts[:return_attrs] && :all != opts[:return_attrs]
        end
        page_urls.each do |url_opt|
          url    = url_opt.first
          Rails.logger.info url
          if url.is_a? Proc
            url.call
            next
          end
          @logger.info 'get', url
          res = get(url)
          doc = Nokogiri::HTML(MultiJson.load(res.body[2..-3])['html'])# .css(@simple_listing_css).each do |simple_doc|
          retrieve_listings(doc).each do |listing|
            next unless listing
            next if !((listing[:title] || listing[:street_address]) || (listing[:lat] && listing[:lng]))
            listing[:city_name] ||= @city_name
            listing[:state_name] ||= @state_name
            check_title(listing)
            listing = check_flag(listing)
            listings = [listing].flatten
            if opts[:return_attrs].present?
              if Symbol === opts[:return_attrs]
                if opts[:return_attrs] == :all
                  results << listings
                else
                  results[opts[:return_attrs]] << listings.map{|s| s[opts[:return_attrs]]}
                end
              else
                results << listings.map{|s| s.slice opts[]}
              end
            end
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
        results
      end

      def base_listings_url
        domain_name
      end

      def base_url
        nestiolistings_url + "&callback=d&_=" + (Time.now.to_i + 100 + rand(100)).to_s
      end

      def retrieve_listings(doc)
        url = base_listings_url
        trs = doc.css('.units-list tr')
        trs = doc.css('tr') if trs.blank?
        # tr_details = doc.css('tr.detail')
        listings = []
        city_name = nil
        raw_neighborhood = nil
        trs.each_with_index do |tr_html, index|
          if tr_html['class'] == 'header'
            city_name = tr_html.text.strip
            raw_neighborhood = nil
            if city_name.downcase.include? 'manhattan'
              city_name = 'manhattan'
            end
            next
          end
          if tr_html['class'] == 'subheader'
            raw_neighborhood = tr_html.text.strip
            next
          end
          next unless tr_html['class'].include? 'unit'
          listing = {flag: 1, city_name: city_name, raw_neighborhood: raw_neighborhood}
          listing[:title] = tr_html.css('.building .name').text.strip
          listing[:unit] = tr_html.css('.unitnum').text.strip
          listing[:beds] = tr_html.css('.layout').children.first.text.strip.to_f
          listing[:baths] = tr_html.css('.layout .bathrooms').text.strip.to_f
          listing_url = url + '#' + tr_html['id']
          listing[:url] = listing_url
          price = tr_html.css('.rent').text.strip
          available = tr_html.css('.available.last').text
          is_available = true
          if available.present? && @listing_callback && @listing_callback[:available]
            is_available = @listing_callback[:available].call available
          else
            is_available = available.include?('Available')
          end
          if price.include?('N/A') || !is_available
            # Spider::ImproveListing.expired_for_url listing_url
            next
          else
            listing[:price] = price.remove(/\D/)
          end
          detail = trs[index + 1]
          listing[:amenities] = detail.css('.other-amenities li').map{|s| s.text.strip}
          listing[:images] = detail.css('.photos a').map{|s| {origin_url: s['href']}} 
          listing[:description] = detail.css('.description').text.strip
          listing[:city_name] ||= 'new york'
          #listing[:state_name] ||= 'ny'
          retrieve_broker listing
          retrieve_contact detail, listing
          if @listing_callback.present?
            @listing_callback.each do |key, callback|
              next if key == :available
              listing[key] = callback.call(listing[key])
            end
          end
          listings << listing
        end
        listings
      end

      def retrieve_contact detail, listing
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
      end
    end
  end
end
