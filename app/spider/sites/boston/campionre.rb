module Spider
  module Boston
    class Campionre < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        #@proxy_host ||= Settings.proxy_host
        #@proxy_port ||= Settings.proxy_port
        @simple_listing_css = 'article.act'
        @listing_image_css = 'div.slides img'
        @listing_callbacks = {
          image: ->(img){
            urls = img['src'].split('&')
            urls.first + '&' + urls.last
          }
        }
      end

      def domain_name
        'http://www.campionre.com/'
      end

      def base_url(flag)
        unless flag.start_with?('sale')
          abs_url('/listings/?t=10&s=-Modification%20Date')
        else
          abs_url('/listings/?t=4,41,42,43&s=-Modification%20Date')
        end
      end

      def login!
        param = {
          Username: 'luizemar98@gmail.com',
          Password: 'cityspade@gz' }
        login_url = abs_url('/user/login/login/')
        post login_url, param
      end

      def page_urls(opts={})
        login!
        opts[:flags] ||= %w{rents sales}
        opts[:sales_num] ||= 600
        opts[:rents_num] ||= 1000
        urls = []
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          (0..opts["#{flag}_num".to_sym]/60).each do |i|
            urls << [base_url(flag) + "&r=#{i * 60 + 1}-#{ (i + 1) * 60 }", flag_i]
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        link = simple_doc.css('a.slideshow').first
        abs_url(link['href'])
      end

      def retrieve_detail(doc, listing)
        return if doc.css('h1 .address').blank?
        listing[:title] = doc.css('h1 .address').first.text
        agent = doc.css('.agent-info-agent').first
        if agent
          agent_name = (agent.css('h3').first.try(:text) || '').sub(/Agent\:/, '').strip
          agent_tel  = (agent.css('.cell,.custom-office-phone,.phone').first.try(:text) || '').gsub(/\D/, '')
          listing[:contact_name] = agent_name
          listing[:contact_tel]  = agent_tel
        else
          tel = doc.css('div.office-info .office-phone').first
          if tel
            listing[:contact_tel] = tel.text.gsub(/\D/, '')
            listing[:contact_name] = 'Campionre'
          end
        end
        desc = doc.css('section#df-detail-widgets .widget.info-callout.three-two').first
        if desc
          listing[:description] = desc.css('p').text
        end
        listing[:price] = doc.css('ul.detail li.list-price span').text.gsub(/\D/, '')
        listing[:beds] = doc.css('ul.detail li.bedrooms span').text.gsub(/\D/, '')
        listing[:baths] = doc.css('ul.detail li.baths span').text
        listing[:zipcode] = doc.css('ul.detail li.zip span').text
        listing[:neighborhood_name] = doc.css('ul.detail li.neighborhood span').text
        listing[:unit] = doc.css('ul.detail li.unit-number span').text
        listing[:amenities] = doc.css('ul.detail li.amenities span,ul.detail li.amenities li').map{|s| s.text.split(',')}.flatten.map(&:strip)

        retrieve_broker(doc, listing)
        return {} if listing[:beds] == '' || listing[:baths] == ''
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Campion And Company",
          tel: "6172360711",
          street_address: "172 Newbury Street Boston MA",
          zipcode: "02116",
          website: domain_name,
          introduction: "As Boston’s pre-eminent real estate firm, Campion and Company has become the broker of choice for individuals and families seeking to buy and sell luxury real estate in Boston and the surrounding suburbs. Specializing in homes for sale in Back Bay, Beacon Hill, the South End and beyond, Campion and Company’s clients include some of the City’s most influential individuals, developers and institutions, all of whom choose to work with the Campion team for an unparralled record of client service as well as specialized and highly effective marketing and negotiation techniques."
        }
      end

      def retrieve_listing(simple_doc, flag_i)
        listing = super
        if listing
          listing[:lat], listing[:lng] = eval(simple_doc['data-geo'])
        end
        listing
      end

    end
  end
end
