require 'open-uri'
require 'net/http'
require 'openssl'
require 'watir'
require 'phantomjs'
require 'capybara/poltergeist'

module Spider
  module Improve
    class DeleteListing
      PROC_DELETE = {
        ## NYC
        'nestseekers' => ->(doc, listing) {
          title = doc.css('title').first
          hash = {}
          if title
            if title.text.downcase.include?('deleted')
              hash = {status: 1}
            end
          end
          if doc.css('.curved.gone').first
            hash = {status: 1}
          else
            hash = {status: 0}
          end
          hash
        },
        'corcoran' => ->(doc, listing){
          title = doc.css('title').first
          hash = {}
          if title
            if title.text.downcase.include?('oops') || doc.css('#price-info .sold-wrapper').first.present?
              hash = {status: 1}
            end
          else
            if doc.css('.sold-wrapper.clearfix.tip').first
              hash = {status: 1}
            end
          end
          hash
        },
        'elliman' => ->(doc, listing){
          if !doc.css('#listing_item').first
            {status: 1}
          elsif msg = doc.css('.w_msg_message').first
            if msg.text.include?('ed') && msg.text.downcase =~ /rent|sold/ || msg.text.downcase.include?('closed')
              {status: 1}
            else
              {status: 2}
            end
          else
            {status: 0}
          end
        },
        'bhsusa' => ->(doc, listing){
          if doc.css('.contract-signed').first
            {status: 2}
          elsif  doc.css('title').text.include?('Not Found') || (doc.css(".content").first && doc.css('.content').text.include?('Sorry, an error occured'))
            {status: 1}
          else
            {status: 0}
          end
        },
        'kwnyc' => ->(doc, listing){
          if doc.css('.colored').first && doc.css('.colored').first.text.downcase.strip != 'active'
            {status: 1}
          else
            {status: 0}
          end
        },
        'mns' => ->(doc, listing){
          unless doc.css(".listing-box").first
            {status: 1}
          end
        },
        'halstead' => ->(doc, listing){
          if doc.css('title').text.downcase.include?('not found')
            {status: 1}
          else
            {}
          end
        },
        'citi_habitats' => ->(doc, listing){
          title = doc.css('.listing_h1').first
          if title.blank?
            {status: 1}
          else
            title = doc.css('title').text.downcase
            if title.include?('404') && title.include?('error')
              {status: 1}
            else
              # if doc.to_s.downcase.include?('rented')
              #  {status: 1}
              # else
              {status: 0}
              # end
            end
          end
        },
        'townrealestate' => ->(doc, listing){
          if doc.css('.box-content table').first.blank?
            {status: 1}
          elsif doc.css('div.listing_details').text =~ /rented/i
            {status: 1}
          else
            {status: 0}
          end
        },
        'bigapplenyc' => ->(doc, listing){
          if doc.css('.rightcolumnDiv').text.strip.include?("Error")
            {status: 1}
          else
            {status: 0}
          end
        },
        ## Brooklyn
        'aptsandlofts' => ->(doc, listing){
          if doc.css("h1.grid_12").text == "Page Not Found"
            {status: 1}
          elsif !doc.css("#property-photos p.taken").text.blank?
            {status: 1}
          else
            {status: 0}
          end
        },
        ## Philly
        'allandomb' => ->(doc, listing){
          if doc.css("#row4 #c2 span.blueCaps div:last").text.strip.blank?
            {status: 1}
          else
            {status: 0}
          end
        },
        'phillyapartmentco' => ->(doc, listing){
          if doc.css("#left_section h1").text.strip == 'Property Not Register'
            {status: 1}
          else
            {status: 0}
          end
        },
        'maxwellrealty' => ->(doc, listing){
          if doc.css("#listingDateValue").text.strip != 'Active'
            {status: 1}
          else
            {status: 0}
          end
        },
        ## Boston
        #'blueskyboston' => ->(doc, listing){
        #  if doc.css('.post-contents').text.include?('error')
        #    {status: 1}
        #  else
        #    {status: 0}
        #  end
        #},
        ##  bostonproperrealestate.com
        #'speedhatch' => ->(doc, listing){
        #  {status: 0}
        #},
        #'bushari' => ->(doc, listing){
        #  {status: 0}
        #},
        'campionre' => ->(doc, listing){
          if (doc.css('#df-detail-view').blank?) || (doc.text.include?('Recommended Searches by'))
            {status: 1}
          else
            {status: 0}
          end
        },
        #'centrerealtygroup' => ->(doc, listing){
        #  {status: 1}
        #},
        'livecharlesgate' => ->(doc, listing){
          site_text = doc.css(".uk-container").text.downcase
          if site_text.include?('is no longer on the market or has been removed') ||
             site_text.include?('listing not found') ||
             site_text.include?('off market')
            {status: 1}
          else
            {status: 0}
          end
        },
        'glenwoodnyc' => ->(doc, listing){
          if doc.css('.prop > h2').text.downcase.include?('not found')
            {status: 1}
          else
            {status: 0}
          end
        },
        #'properrg' => ->(doc, listing){
        #  if doc.css('title').text.downcase.include?('nothing found')
        #    {status: 1}
        #  elsif doc.css('.listing-header-stats').text.include?('Off')
        #    {status: 1}
        #  else
        #    {status: 0}
        #  end
        #},
        'securecafe' => ->(doc, listing){
          available_apt_units = Array.new
          doc.css(".AvailUnitRow").each{|u| available_apt_units << u.css("td")[0].text.delete("#")}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'exchangeplace' => ->(doc, listing){
          available_apt_units = Array.new
          doc.css(".AvailUnitRow").each{|u| available_apt_units << u.css("td")[0].text.delete("#")}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'phillybozzuto' => ->(doc, listing){
          available_apt_units = Array.new
          doc.css(".AvailUnitRow").each{|u| available_apt_units << u.css("td")[0].text.delete("#")}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'bostonbozzuto' => ->(doc, listing){
          available_apt_units = Array.new
          doc.css(".AvailUnitRow").each{|u| available_apt_units << u.css("td")[0].text.delete("#")}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'propertylink' => -> (doc, listing){
          available_apt_units = Array.new
          doc.css('.unit').each{|u| available_apt_units << u.css("td")[1].text}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'diversesolutions' => -> (doc, listing){
          docJSON = JSON.parse(doc)
          if docJSON["PropertyTypes"] != nil
            if docJSON["PropertyTypes"][0]["FeedID"] == 0
              return {status: 0}
            end
          else
            #Rental property price cannot exceed $12000
            if (listing[:flag] == 1) && (listing[:price] > 12000)
              return {status: 0}
            else
              return {status: 1}
            end
          end
        },
        'avalonbay' => -> (doc, listing){
          available_apt_units = Array.new
          #listingURI = URI.parse(listing[:url])
          #listingData = Net::HTTP.get(listingURI)
          listingJSON = JSON.parse(doc)
          listingJSON["results"]["availableFloorPlanTypes"].each do |floorPlanTypes|
            floorPlanTypes["availableFloorPlans"].each do |getDetails|
              getDetails["finishPackages"][0]["apartments"].each do |listingDetail|
                available_apt_units << listingDetail["apartmentNumber"]
              end
            end
          end
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'avaloncove' => -> (doc, listing){
          available_apt_units = Array.new
          #listingURI = URI.parse(listing[:url])
          #listingData = Net::HTTP.get(listingURI)
          listingJSON = JSON.parse(doc)

          listingJSON["results"]["availableFloorPlanTypes"].each do |floorPlanTypes|
            floorPlanTypes["availableFloorPlans"].each do |getDetails|

              #Echoing methods in spider file
              apartmentBlock = getDetails["finishPackages"][0]["apartments"]
              countingIndex = 0

              while (countingIndex < apartmentBlock.length) do
                apartmentBlock.each do |listingDetail|
                  available_apt_units << listingDetail["apartmentNumber"]
                  countingIndex = countingIndex + 1
                end
              end
            end
          end

          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'avalonbayboston' => -> (doc, listing){
          available_apt_units = Array.new
          #listingURI = URI.parse(listing[:url])
          #listingData = Net::HTTP.get(listingURI)
          listingJSON = JSON.parse(doc)

          listingJSON["results"]["availableFloorPlanTypes"].each do |floorPlanTypes|
            floorPlanTypes["availableFloorPlans"].each do |getDetails|

              #Echoing methods in spider file
              apartmentBlock = getDetails["finishPackages"][0]["apartments"]
              countingIndex = 0

              while (countingIndex < apartmentBlock.length) do
                apartmentBlock.each do |listingDetail|
                  available_apt_units << listingDetail["apartmentNumber"]
                  countingIndex = countingIndex + 1
                end
              end
            end
          end

          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'equityresidential' => -> (doc, listing){
          available_apt_units = Array.new
          listingURL = listing[:url]

          Watir.driver = 'webdriver'
          Watir.load_driver
          Selenium::WebDriver::PhantomJS.path = '/usr/local/bin/phantomjs'

          #Using Phantomjs to get listing unit
          browser = Watir::Browser.new(:phantomjs)
          browser.goto(listingURL)
          browser.link(text: 'All floorplans').click
          doc = Nokogiri::HTML(browser.html)

          doc.css('.unit').each do |u|
            available_apt_units << (u.css("h4").text).delete(" ").delete("Unit")
          end

          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'equityresidentialboston' => -> (doc, listing){
          available_apt_units = Array.new
          listingURL = listing[:url]

          Watir.driver = 'webdriver'
          Watir.load_driver

          Selenium::WebDriver::PhantomJS.path = '/usr/local/bin/phantomjs'
          #Using Phantomjs to get listing unit
          browser = Watir::Browser.new(:phantomjs)
          browser.goto(listingURL)
          browser.link(text: 'All floorplans').click
          doc = Nokogiri::HTML(browser.html)

          doc.css('.unit').each do |u|
            available_apt_units << (u.css("h4").text).delete(" ").delete("Unit")
          end

          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'chicagobozzuto' => ->(doc, listing){
          available_apt_units = Array.new
          doc.css(".AvailUnitRow").each{|u| available_apt_units << u.css("td")[0].text.delete("#")}
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'twotree' => -> (doc,listing){
          available_apt_units = Array.new
          page = Nokogiri::HTML(open("http://streeteasy.com/building/mercedes-house"))
          table_section = page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")
          table_section.css("tr").each do |u|
            unit_match = (/- /).match(u.css(".address").css("a").text)
            unit = unit_match.pre_match[1..unit_match.pre_match.length-1]
            available_apt_units << unit
          end
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
        'forestcity' => -> (doc,listing){
          available_apt_units = Array.new
          page = Nokogiri::HTML(open("http://streeteasy.com/building/new-york-by-gehry/"))
          table_section = page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")
          table_section.css("tr").each do |u|
            unit_match = (/- /).match(u.css(".address").css("a").text)
            unit = unit_match.pre_match[1..unit_match.pre_match.length-1]
            available_apt_units << unit
          end
          if available_apt_units.include?(listing[:unit])
            return {status: 0}
          else
            return {status: 1}
          end
        },
      }
    end
  end
end
