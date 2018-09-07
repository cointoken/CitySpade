# encoding: utf-8
module Spider
  module Sites
    ##  listing 爬取基类
    ##   子类中需要以下实现以下方法
    ##  retrieve_detail 获取listing 信息
    ##  page_urls 每页listing url
    ##  get_listing_url 取 listing origin_url
    class Base < Spider::Base
      def initialize(opt = {})
        super
        @simple_listing_css = ".listing"
        @listing_image_css  = ".listing-img img"
        @listing_callbacks = {}
        @check_url = nil
        @city_name = 'new york'
        ## check listing if ok
        # eg @check_listing ={zipcode: ->(code){ code =~ /^1/ }}
        #    listing(zipcode: 10012) => ok
        #    listing(zipcode: 20012) => fail
        @check_listing = nil
      end
      attr_reader :check_listing

      def page_urls(opts={})
        @logger.info 'please rewrite the method'
        []
      end

      def get_listing_url(simple_doc)
        raise 'please rewrite the method to get listing origin url'
      end

      def listings(opts={return_attrs: :url})
        results= []
        if opts[:return_attrs].present?
          results ={opts[:return_attrs] => []} if Symbol === opts[:return_attrs] && :all != opts[:return_attrs]
        end
        page_urls(opts).each do |url_opt|
          flag_i = url_opt[1] || 1
          url    = url_opt.first
          Rails.logger.info url
          if url.is_a? Proc
            url.call
            next
          end
          @logger.info 'get', url
          if url_opt.size == 3 && Hash === url_opt[2]
            res = post(url, url_opt[2])
          else
            res = get(url)
          end
          if res.code == '200'
            if @get_listing_lists
              lls = @get_listing_lists.call(res.body)
            else
              lls = Nokogiri::HTML(res.body)
            end
            lls.css(@simple_listing_css).each do |simple_doc|
              listing = retrieve_listing(simple_doc, flag_i)
              next unless listing
              next if !((listing[:title] || listing[:street_address]) || (listing[:lat] && listing[:lng]))
              listing[:city_name] ||= @city_name
              listing[:state_name] ||= @state_name
              check_title(listing)
              listing = check_flag(listing)
              next if listing.blank?
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
          else
            []
          end
        end
        results
      end

      def retrieve_listing(simple_doc, flag_i = 1)
        listing = {flag: flag_i}
        if @get_url_args && @get_url_args == 2
          listing[:url]= url = get_listing_url(simple_doc, listing)
        else
          listing[:url]= url = get_listing_url(simple_doc)
        end
        return nil unless url
        if @check_url
          return nil unless @check_url.call(url)
        end
        if Array === listing[:url]
          url = url[1..-1]
          listing[:url] = listing[:url].first
        end
        if @get_custom_html
          body = @get_custom_html.call(url)
          doc = Nokogiri::HTML(body.to_utf8)
          retrieve_detail(doc, listing)
          retrieve_images(doc, listing) if (listing[:title] || listing[:street_address]) ||(listing[:lat] && listing[:lng])
          listing
        else
          if Array === url
            res = post url.first, url[1]
          else
            res = get(url)
          end
          if res.code == '200'
            doc = Nokogiri::HTML(res.body.to_utf8)
            retrieve_detail(doc, listing)
            retrieve_images(doc, listing)
            listing
          else
            nil
          end
        end
      end

      def retrieve_images(doc, listing, opt={})
        return nil if listing.blank?
        listing[:images] = []
        doc.css(@listing_image_css).each do |img|
          callback = opt[:callback] || @listing_callbacks[:image]
          if callback
            origin_url = callback.call(img)
          else
            if img.name.downcase == 'a'
              origin_url = abs_url(img['href'])
            else
              origin_url = abs_url(img['src'])
            end
            origin_url = origin_url.remove(/\?\d+/)
          end
          listing[:images] << {origin_url: origin_url} if origin_url.present?
        end
        listing
      end

      def get_agent_url(doc)
        url_doc = doc.css(@listing_agent_css)
        url_doc.present? ? abs_url(URI.escape(url_doc.attr("href").value)) : false
      end

      def get_agent_doc(url)
        res = get(url)
        res.code == '200' ? Nokogiri::HTML(res.body) : false unless res.blank?
      rescue
        false
      end

      private
      def check_title(listing)
        return false if !listing || listing.blank?
        listing[:beds] = listing[:beds].gsub(/^\D+|\D+$/, '') if String === listing[:beds]
        listing[:baths] = listing[:baths].sub(/^\D+|\D+$/, '') if String === listing[:baths] #&& listing[:baths] =~ /\D$/
        if listing[:title].present?
          listing[:title] = listing[:title].split(',').first
          listing[:title].sub!(/\(.+\)/, '')
          if listing[:title] =~ /\sJunior\s4($|\s)/i or listing[:title] =~  /\sJR4(\s|$)/
            listing[:title].sub(/\s(Junior\s4|JR4)($|\s)/, '')
            listing[:beds] ||= 1
          end

          ## get unit from title
          if listing[:unit].blank? && listing[:title].split(/\s/).last =~ /\d/
            unit = listing[:title].split(/\s/).last
            if unit !~ /[A-z]{2}/
              listing[:unit] = unit
              listing[:title].remove!(/#{unit}$/)
            end
          end
          listing[:title].strip!
          if listing[:title] =~ /(\d+(\.\d)?\s(bd|bed|br|bath)(\s|\,|\||$|\.|\:))|(studio)/i
            listing.delete :title
            listing[:is_full_address] = false if listing[:is_full_address].nil? || listing[:is_full_address]
          elsif listing[:is_full_address].nil? || listing[:is_full_address]
            if listing[:title] =~ /^\d+\s/
              listing[:is_full_address] = true
            elsif listing[:title] =~ /^\d+\-\d+/
              listing[:is_full_address] = true #false
            elsif listing[:title] =~ /\d+.?\s/ && listing[:title].split(/\s/).size > 2
              listing[:is_full_address] = true #false
            else
              listing[:is_full_address] = false
              # listing[:title] = listing[:title].sub(/^\d+\-\d+/, '')
            end
          else
            listing[:is_full_address] = false
          end
        else
          listing[:is_full_address] = false unless listing.blank?
        end
        if listing.present?
          if listing[:no_fee].blank?
            if listing[:amenities].to_s =~ /no\-fee|no\s+fee/i || listing[:description].to_s =~ /no\-fee|no\s+fee/i
              listing[:no_fee] = true
            else
              listing[:no_fee] = nil
            end
          end
        end
        if listing[:raw_neighborhood] && listing[:raw_neighborhood].downcase.include?('other')
          listing.delete :raw_neighborhood
        end
        listing[:contact_name] = nil if listing[:contact_name] && listing[:contact_name].downcase.strip == 'none'
        listing
      end
      def check_flag(listing)
        if listing[:beds] && listing[:price]
          if listing[:flag] == 1
            if [listing[:beds].to_i, 1].max * 100000 < listing[:price].to_i
              listing[:flag] = 0
            end
          else
            if [listing[:beds].to_i, 1].max * 2000 > listing[:price].to_i
              listing[:flag] = 1
            end
          end
        end
        listing = check_other listing
        if Array === listing
          listing.delete_if{|s| s[:price].blank? && s[:beds].blank?}
        else
          listing = nil if listing[:price].blank? && listing[:beds].blank?
        end
        listing
      end

      def check_other(listing)
        lls = listing.delete :listings
        if lls.present?
          listing2 = []
          lls.each do |l, index|
            l_m =  listing.merge(l)
            l_m[:url] += "##{(l[:unit] || index).to_s.remove(/\s/)}" if l_m[:url] && index != 0 && !l_m[:url].include?('#')
            listing2 << l_m
          end
          Spider::ImproveListing.expired_buildings_for_multi_listings_by_urls listing2.map{|l| l[:url]}
          listing = listing2
        end
        listing
      end
    end
  end
end

class String
  def to_utf8
    self.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
    self.encode!('UTF-8', 'UTF-16')
  end
  def to_number
    {one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10}[self.downcase.to_sym] || 0
  end
end
