module Spider
  module NYC
    class Rutenbergrealtyny < Spider::NYC::Base
      def initialize
        super
        @listing_agent_css = ".agent-info"
        @simple_listing_css = ".search-results .text-dark h4 a"
        @listing_image_css = ".panel-details-gallery img"
      end

      def domain_name
        'http://www.rutenbergrealtyny.com'
      end

      def base_url
        domain_name + "/result.aspx"
      end

      def page_urls(opts)

        urls = []
        70.times do |t|
          urls << [base_url + "?page=#{t+1}&PropertyType=82&area=manhattan&MinBedrooms=-2&MinBaths=&MinPrice=&MaxPrice=", 1]
        end
        urls
      end

      def get_listing_url(simple_doc)
        if is_full_address? simple_doc.text.strip
          abs_url simple_doc.attr("href")
        else
          nil
        end
      end

      def retrieve_detail(doc, listing)
        pd = doc.css(".container .row .panel-details")
        listing[:title] = pd.css(".panel-details-gallery-caption h5").text.strip
        return {} unless is_full_address?(listing[:title])
        g_dels = pd.css(".col-md-6 .dl-horizontal")
        g_dels.css("dt").each_with_index do |gd, i|
          listing[:price] = g_dels.css("dd")[i].text.gsub(/\D/, "") if gd.text =~ /rent/i
          listing[:beds] = g_dels.css("dd")[i].text.strip.to_f if gd.text =~ /bedrooms/i
          listing[:baths] = g_dels.css("dd")[i].text.strip.to_f if gd.text =~ /bathrooms/i
          listing[:listing_type] = g_dels.css("dd")[i].text.strip if gd.text =~ /buliding type/i
          listing[:unit] = g_dels.css("dd")[i].text.split("/").last.strip if gd.text =~ /floors\/apts/i
        end
        listing[:raw_neighborhood] = pd.css(".propinfo .location").text.strip
        listing.delete :unit if listing[:unit] == '0'
        listing[:description] = pd.css(".col-sm-11 .pad4 p").text.strip
        listing[:amenities] = pd.css(".col-sm-11 .pad2 dl dt").map(&:text)
        listing[:is_full_address] = true
        script = doc.css('script[type="text/javascript"]').text
        m = script.match(/\s(\d{5})\'/)
        if m
          listing[:zipcode] = m[1]
        end
        listing.delete :raw_neighborhood if listing[:zipcode]
        retrieve_agents doc, listing
        retrieve_broker doc, listing
        retrieve_images doc, listing
        retrieve_open_houses doc, listing

        if listing[:agents].blank?
          listing[:contact_name] = listing[:broker][:name]
          listing[:contact_tel] = listing[:broker][:tel]
          retrieve_open_houses doc, listing
        else
          listing[:contact_name] = listing[:agents].first[:name]
          listing[:contact_tel] = listing[:agents].first[:tel]
        end

        listing
      end

      def retrieve_agents doc, listing
        agents = []
        agent_infos = doc.css(@listing_agent_css)
        agent_infos.each do |agent_info|
          agent = {}
          agent[:name] = agent_info.css(".agent-name").text.strip

          agent_info.css(".agent-contact").text.strip.split("\n").each do |tel|
            agent[:tel] = tel.split("x").first.gsub(/\D/, "") if tel.match(/o\:/i)
            agent[:office_tel] = tel.split("x").first.gsub(/\D/, "") if tel.match(/o\:/i)
            agent[:mobile] = tel.split("x").first.gsub(/\D/, "") if tel.match(/m\:/i)
          end

          agent[:origin_url] = abs_url agent_info.css(".green").attr("href").value
          #agent[:email] = agent_info.css(".email")
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: 'Charles Rutenberg, LLC',
          street_address: "127 East 56th Street 4th Floor",
          email: 'info@rutenbergnyc.com',
          state: 'NY',
          tel: '2126881000',
          website: 'http://www.rutenbergrealtyny.com/',
          introduction: %q{
            Co-founded seven years ago by Wall Street veteran Richie Friedman and real estate veteran Joseph Moshe, Rutenberg’s New York City operation has grown over 30% in the last year, adding more than 500 brokers to the company since its inception and ranking the 6th largest Manhattan residential brokerage in terms of number of agents. Unlike the traditional real estate model, Rutenberg’s unique structure allows the broker greater freedom and more success in running their own business.
          }
        }
      end

      def retrieve_open_houses doc, listing
        ohs = doc.css(".openhouse")
        if ohs.present?
          oh_hash = []
          ohs.each do |oh|
            oh.text.split("|").each do |o|
              o.remove!(/open house(s{0,1})\:/i)
              text = o.split('(', 2).first
              tts = text.split(/\,\s+(?=\d)/, 2)
              hash = {open_date: Date.parse(tts[0])}
              tms = tts.last.split('-', 2)
              tms.map!{|tm|
                if tm.to_i < 8
                  tm << ' PM'
                else
                  tm << ' AM'
                end
              }
              hash[:begin_time] = tms[0]
              hash[:end_time]   = tms[1]
              oh_hash << hash
            end
          end
          listing[:open_houses] = oh_hash
          listing
        end
      end
    end
  end
end
