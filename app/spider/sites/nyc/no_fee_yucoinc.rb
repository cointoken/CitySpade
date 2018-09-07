module Spider
  module NYC
    class Yucoinc < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '#subContent table tr td a'
        @listing_image_css = "#subContent table tr td a"
        @listing_callbacks[:image] = ->(img){
          abs_url 'availabilities/' + img['href']
        }
      end

      def domain_name
        'http://www.yucoinc.com/'
      end

      def page_urls(opts={})
        urls = []
        3.times do|i|
          urls << ["http://www.yucoinc.com/availabilities/?pCategoryId=1&pTRows=12&pPNum=#{i}", 1]
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url 'availabilities/' + simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        trs = doc.css('#subContent table tr td table tr')
        opt = {}
        trs.each do|tr|
          th = tr.css('th')
          td = tr.css('td')
          opt[th.text.strip.underscore.remove(/\W/)] = td.text.strip
        end
        listing[:price] = opt['monthlyrent'].gsub(/\D/, '')
        listing[:beds] = opt['size'].split(" ")[0].to_number.to_f
        description = doc.css('#subContent table')[1].css('p')[1].text.strip
        listing[:description] = description
        obj = doc.css('#subContent table')[0].css('p')[1].text.split(",")
        listing[:raw_neighborhood] = obj[0].strip
        listing[:city_name] = obj[1].strip
        title = doc.css("#subContent tr td h1").text.strip
        listing[:title] = title
        listing[:contact_tel] = "2129942200"
        listing[:contact_name] = "Yuco Management, Inc"
        listing[:broker] = {
          name: "Yuco Management, Inc",
          email: "rentals@yucoinc.com",
          tel: "2129942200",
          street_address: "200 Park Avenue, 11th Floor",
          zipcode: "10166",
          website: domain_name
        }
        retrieve_open_house trs, listing if trs.last.text =~ /Show Dates & Times:/ && trs.last.css('td').text !~ /Appointment/ 
        listing
      end

      def retrieve_open_house trs, listing
        listing[:open_houses] = []
        arr = trs.last.css('td').to_html.split(/<br>/).reject &:blank?
        arr = arr.map{|arr|arr.remove(/<td>|<\/td>/)}.reject &:blank?
        arrs = arr.each_slice(2).to_a
        arrs.each do|arr|
          open_date = Date.parse(arr[0])
          begin_and_end_time = arr[1].split("to")
          begin_time = Time.parse(begin_and_end_time[0])
          end_time = Time.parse(begin_and_end_time[1])
          open_houses = {open_date: open_date, begin_time: begin_time, end_time: end_time}
          listing[:open_houses] << open_houses
        end
      end

    end
  end
end
