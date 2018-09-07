module Spider
  module Boston
    class Centrerealtygroup < Spider::Boston::Base
      ## not have agent info
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '#dsidx-listings .dsidx-listing .dsidx-primary-data div a'
        #@listing_image_css = 'table tr td .jb-idx-thumb img'
        #@listing_callbacks[:image] = ->(img){
          #abs_url(img['src'].gsub(/medium/, 'full')) unless img.blank?
        #}
      end

      def domain_name
        'http://centrerealtygroup.com/'
      end

      def page_urls(opts={})
        opts[:flags] = %w{rents sales}
        urls = []
        opts[:flags].each_with_index do |flag, index|
          flag_i = get_flag_id(flag)
          if flag_i == 1
            @simple_listing_css = '.dsidx-results .dsidx-prop-summary .dsidx-prop-title b a'
            40.times do |num|
              urls << [abs_url(
                "idx/city/boston/page-#{num + 1}?idx-q-PropertyTypes=158&idx-d-SortOrders%3C0%3E-Column=DateAdded&idx-d-SortOrders%3C0%3E-Direction=DESC"
                ), flag_i]
            end
          else
            @simple_listing_css = '#dsidx-listings .dsidx-listing .dsidx-primary-data div a'
            urls << [abs_url("sales-search/boston-sales-listings/"), flag_i]
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        title_str = doc.css(".entry-header .entry-title").text
        listing[:title] = title_str.split(',').first
        unit = title_str.split(',').select{|s| s =~ /Unit/}.first
        listing[:unit] = unit.sub(/unit/i, "").strip if unit
        zip  = title_str.split(',').select{|s| s =~ /MA/}.first
        if zip
          zip = zip.split('(').first.remove(/\D/)
          listing[:zipcode] = zip if zip.size == 5
        end
        listing[:price] = doc.css("#dsidx-price td").text.gsub(/[\s,\$]/, '')
        if listing[:price].blank?
          listing[:status] = 1
        else
          listing[:beds] = doc.css(".dsidx-secondary-row")[0].css("td").text.gsub(/\D/, '')
          baths = doc.css("#dsidx-primary-data tr")[3].css('td').text.split(',') unless doc.css("#dsidx-primary-data tr")[3].blank?
          listing[:baths] = baths.first.gsub(/\D/, '').to_i
          listing[:baths] += 0.5 if baths.size > 1
          listing[:sq_ft] = doc.css(".dsidx-secondary-row")[1].css("td").text.gsub(/\D/, '') unless doc.css(".dsidx-secondary-row")[1].blank?
          listing[:description] = doc.css("#dsidx-description-text").text.strip
        end
        providor = doc.css('#dsidx-listing-source').text.split(' by ').last#.strip
        if providor
          providor = providor.strip
          agent_and_broker = providor.split(",")
          if agent_and_broker.size == 2
            if agent_and_broker.last.size > 10
            listing[:broker_name] = agent_and_broker[1].strip
            listing[:contact_name] = agent_and_broker[0].strip
            else
              listing[:broker_name] = providor
              listing[:contact_name] = providor
            end
          elsif agent_and_broker.size > 2
            listing[:broker_name] = agent_and_broker[1..-1].join(',').strip
            listing[:contact_name] = agent_and_broker[0].strip
          else
            listing[:broker_name] = agent_and_broker[0].try(:strip)
            listing[:contact_name] = agent_and_broker[0].try(:strip)
          end
        end
        # listing[:contact_name] = "Brighton Office"
        # listing[:contact_tel] = "6173320077"
        # retrieve_broker(doc, listing)
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Centre Realty Group",
          tel: "6173320077",
          website: domain_name,
          introduction: "When you list your home with Centre Realty Group, our agents will contact you to set the listing process in motion. We start with a successful pricing strategy followed by a very concentrated effort to market your listing online with key technology to attract qualified buyers or tenants. Our agents will guide you through the process from negotiation through closing, if needed."
        }
      end

      def retrieve_images(doc, listing)
        if image_url = get_image_url(doc)
          res = get image_url
          return listing unless res.code.to_i == 200
          xml = Nokogiri::XML(res.body)
          listing[:images] = []
          xml.css('image').each do |img|
            listing[:images] << {origin_url: img['imageURL']} unless img['imageURL'].include?('no-photos-available')
          end
        end
        listing
      end

      def get_image_url(doc)
        if doc.css('input[name="propertyID"]').present?
          id = doc.css('input[name="propertyID"]').first['value'].strip
          if id
            "http://centrerealtygroup.com/wp-content/plugins/dsidxpress/client-assist.php?action=GetPhotosXML&pid=#{id}"
          end
        else
          nil
        end
      end

    end
  end
end
