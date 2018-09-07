require 'open-uri'
require 'net/http'
require 'openssl'
require 'watir'
require 'phantomjs'
require 'capybara/poltergeist'

module Spider
  module Boston
    class EquityResidentialBoston < Spider::Boston::Base

      def initialize(accept_cookie: true)
        super
        @urls = []
        Watir.driver = 'webdriver'
        Watir.load_driver
        Selenium::WebDriver::PhantomJS.path = '/usr/local/bin/phantomjs'
      end

      #private :domain_name, :base_url

      def get_listing_url
        url = "http://www.equityapartments.com/massachusetts/boston-apartments.aspx"
        doc = Nokogiri::HTML(open(url))
        doc.css('.srpMarket').each do |city|
          #unless (city.at_css('.srpMarketHeader h3').text.eql? "Jersey City")
          city.css('.srpCommunity').each do |links|
            @urls << links.at_css('a')['href']
          # end
          end
        end
        @urls
      end

      def extract_price(unit)
        price = unit.split('$')
        price = price[1] #Gets the second element of the array, that is price
        price = price.delete(',')

        price = price.to_i
        price
      end


      def retrieve_description(listing, url)
        browser = Watir::Browser.new(:phantomjs)
        browser.goto(url)
        sleep(3)
        browser.link(text: 'Community Features').click
        sleep(5)
        doc = Nokogiri::HTML(browser.html)
        browser.close
        listing[:description] = doc.at_css('#communityDescription').text.strip
        listing
      end

      #def retrieve_agents(listing)
      #  agents = []
      #  agent = Hash.new
      #  agent_url = "http://www.equityapartments.com/contact-us.aspx"
      #  agent[:name] = "Equity Apartments"
      #  agent[:tel] = "6468333960"
      #  agent[:website] = agent_url
      #  agent[:origin_url] = agent_url
      #  agents << agent
      #  listing[:agents] = agents.reject{|a| a=={}}
      #end

      def retrieve_images(listing, photo_url, floorplan)
        listing[:images] = Array.new
        #listing[:images] << { origin_url: floorplan.at_css('a img')['src'] }
        doc = Nokogiri::HTML(open(photo_url))
        interior_images = doc.css('.row').first 
        interior_images.css('a').each do |image|
          listing[:images] << { origin_url: image['href'] }
        end
        listing
      end

      def listings(options={})
        get_listing_url.each do |url|
          doc = Nokogiri::HTML(open(url))
          document = doc.css('#addressText span')
          title = document[0].text.strip.chomp(",")
          neighborhood_name = document[1].text.strip.chomp(",")

          state_name = "MA" #Massachussetts 

          phone = doc.at_css('#address p').text.strip
          photo_url = doc.at_css('#navTabs #tab-gallery a')['href']
          browser = Watir::Browser.new(:phantomjs)
          browser.goto(url)
          browser.link(text: 'All floorplans').click
          sleep(10)
          doc = Nokogiri::HTML(browser.html)

          #Phone Number Trim
          phone = phone.delete("()").delete(" ").delete("-")

          doc.css('.floorplan').each do |floorplan|
            if browser.element(class: 'viewUnits').exists?
              #puts floorplan.at_css('h3').text.strip
              plan = floorplan.css('p')
              if (floorplan.next_element != nil)
                units = floorplan.next_element
                units.css('.unit').each do |unit|
                  listing = {}
                  #listing[:listing_type] = listing_type
                  listing[:flag] = 1
                  listing[:title] = title
                  listing[:is_full_address] = true
                  #LISTING UNIT NEEDS SOME HANDLING
                  #listing[:unit] = unit.css("h4").text
                  listing[:unit] = (unit.css("h4").text).delete(" ").delete("Unit")

                  listing[:city_name] = neighborhood_name
                  listing[:state_name] = state_name
                  listing[:contact_name] = "Equity Residential"
                  listing[:contact_tel] = phone
                  listing[:url] = url
                  listing[:no_fee] = true
                  unit.search('.terms').remove
                  listing[:beds] = plan[0].text[/(\d+)/].to_f
                  listing[:baths] = plan[1].text[/(\d+)/].to_f
                  listing[:price] = extract_price(unit.css('p').text)
                  retrieve_description(listing,url)
                  #retrieve_agents(listing)
                  retrieve_images(listing, photo_url, floorplan)

                  next unless listing
                  check_title listing

                  if block_given?
                    @logger.info listing
                    yield(listing)
                  else
                    p listing
                  end
                end
              end
            end
          end
        end
      end

      #def listings(options={})
      #  get_listing_url.each do |url|
      #    #@logger.info 'get url', url
      #    #res = get(url)
      #    #if res.code == '200'
#
      #    #Retrieving listings within a building
      #    retrieve_listing(url)
      #      #check_title listing
      #    #else
      #    #  []
      #    #end
      #  end
      #end
    end
  end
end
