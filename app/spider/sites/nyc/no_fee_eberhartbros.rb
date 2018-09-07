module Spider
  module NYC
    class Eberhartbros < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "tr.results a"
        @listing_image_css = "#gallery li a"
        @listing_callbacks[:image] = ->(img){
          abs_url img['href']
        }
      end

      def domain_name
        'http://www.eberhartbros.com/'
      end

      def page_urls(opts = {})
        urls = []
        flag_i = get_flag_id("rent")
        url = "http://www.eberhartbros.com/search_results.php?search=standard&sorter=dateavail_year,dateavail_month,dateavail_day&locationid=&lowprice=0&highprice=4294967295&numbedrooms"
        urls << [url, flag_i]
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc["href"]
      end

      def retrieve_detail(doc, listing)
        trs = doc.css('table tr')
        opts = {}
        trs.each do|tr|
          tds = tr.css('td')
          if tds.size == 2
            opts[tds[0].text.strip.underscore.remove(/\W/)] = tds.last.text.strip
          end
        end
        listing[:price] = opts['price'].gsub(/\D/, '')
        listing[:beds] = opts['bedrooms'].to_f
        listing[:baths] = opts['bathrooms'].to_f
        listing[:no_fee] = true
        description = doc.css('table table table tr').last.css('div')[1].text.strip#.text.strip.split('Description').second.split("\n\n\n").first
        listing[:description] = description
        tds = doc.css('table tr td table tr td table tr td').text.strip.split("\n")
        listing[:title] = tds.first.strip
        listing[:unit] = tds[3].strip
        listing[:contact_name] = "Eberhart Brothers Inc"
        listing[:contact_tel] = "2125702400"
        listing[:broker] = {
          name: "Eberhart Brothers Inc",
          tel: "2125702400",
          email: "rentals@eberhartbros.com",
          street_address: "312 E. 82nd St.",
          zipcode: "10028",
          website: domain_name,
          introduction: %q{Founded in 1927, Eberhart Brothers Inc. is a family-run real estate company that owns and manages more than 1,000 apartments in some of Manhattan's most desirable neighborhoods. We are justly proud of an unbroken 80-year history of first-rate design and construction, as well as our attentive personal service to tenants.
                           Most of our apartments are located in low-rise buildings with turn-of-the-century charm and high ceilings that are seldom found in new construction. Our in-house architectural and construction-management staff produces a wide range of stylish and well-finished apartments that appeal to a wide variety of residents.
                           Eberhart Brothers offers rental units in many different sizes and configurations, including studios to four-bedroom apartments and two- to three-story penthouses. Many apartments also have garden patios or rooftop terraces. We are confident you will find the right apartment for you among the wide variety in our portfolio.
                           Lastly, our leasing agents are available seven days a week without appointment. Many of our staff are also our tenants and are justifiably proud of what they do.
                          }
        }
        retrieve_open_houses(doc, listing)
        listing
      end

      def retrieve_open_houses doc, listing
        open_houses= []
        doc.css("#main_container table table table td div div p").each do |oh|
          if oh.text.present? && oh.text.match(/[(Date\:)(Time\:)]/i)
            open_date = Date.parse(oh.text.split(/Time\:/i).first.remove(/Date\:/i).strip)
            begin_time = Time.parse(oh.text.split(/Time\:/i).last.split(/to/i).first.strip)
            end_time = Time.parse(oh.text.split(/Time\:/i).last.split(/to/i).last.strip)
            open_house = {open_date: open_date, end_time: end_time, begin_time: begin_time}
            open_houses << open_house
          end
        end
        listing[:open_houses] = open_houses if open_houses.present?
      end

    end
  end
end
