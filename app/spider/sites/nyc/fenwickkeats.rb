module Spider
  module NYC
    class Fenwickkeats < Spider::NYC::Base
      def initialize
        super
        @listing_agent_css = "#agentOverview #agentAmazingness"
        @simple_listing_css = ".tableListingContainer table li .specs .button"
        @listing_image_css = "#listingDetail .featureSubMedia table td img"
      end

      def domain_name
        'http://www.fenwickkeats.com'
      end

      def base_url
        domain_name + "/featuredlistings.aspx?strtype=rental"
      end

      def page_urls(opts)
        urls = []
        4.times do |t|
          urls << [base_url + "&page=#{t+1}", 1]
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc.attr("href")
      end

      def retrieve_detail(doc, listing)
        ld = doc.css('#listingDetail')
        if ld.present?
          listing[:title] = ld.css("#listingAddress span").text.split(",").first.strip
          listing[:street_address] = listing[:title]
          listing[:unit] = ld.css("#listingAddress span").text.split(",").last.split(".").last.strip
          listing[:description] = ld.css("#listingInformation").text.strip
          listing[:price] = ld.css("#listinginfo .Rent .informationValue").text.gsub(/\D+/, "")
          ld.css("#listinginfo .informationTitle").each do |li|
            if li.text.strip.match(/Rooms\/Beds\/Baths/i)
              li.text.strip.split("\r\n").first.split("/").each_with_index do |l, i|
                listing[:beds] = l.to_f if i == 1
                listing[:baths] = l.to_f if i == 2
              end
            end
          end
          listing[:listing_type] = ld.css("#propertyinfo .Type .informationValue").text.strip
          listing[:raw_neighborhood] = ld.css("#propertyinfo .Neighborhood .informationValue").text.strip

          listing[:is_full_address] = true
          retrieve_broker doc, listing
          retrieve_agents doc, listing
          listing[:contact_name] = listing[:agents].blank? ? listing[:broker][:name] : listing[:agents].first[:name]
          listing[:contact_tel] = listing[:agents].blank? ? listing[:broker][:name] : listing[:agents].first[:tel]
        else
          #TODO:貌似跳转到http://www.fenwickkeats.com/default.aspx#.VPGCbWSUcjY
          listing[:status] = 2
        end
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        agent_infos = doc.css(@listing_agent_css)
        agent_infos.each do |agent_info|
          agent = {}
          next if agent_info.text.blank?
          agent[:website] = abs_url agent_info.css("a").first.attributes["href"].value
          next if agents.include? agent[:website]
          agent[:name] = agent_info.css(".title strong").text.strip
          agent_info.css("#AgentTitle2").text.split("\n").each do |ag|
            agent[:email] = ag.strip if ag.strip.match(/@/)
            agent[:tel] = ag.strip.gsub(/\D/, "") if ag.strip.match(/\d{1,}\-/)
          end
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: 'FENWICK KEATS Real Estate',
          street_address: "419 Park Avenue South, 7th Floor",
          email: 'fk@fenwickkeats.com',
          state: 'NY',
          tel: '2127551500',
          website: 'http://www.fenwickkeats.com/',
          introduction: %q{
            FENWICK KEATS Real Estate, a Manhattan based brokerage firm, was formed on the simple premise that superior service coupled with comprehensive industry knowledge is what our clients expect and deserve. Created in 1989, by Rob Anzalone and Jeff Wolk, FENWICK KEATS Real Estate has never wavered from this simple mission. Since the firm's inception, our clients, their families and friends, have relied upon us to help them navigate one of the most complex real estate markets in the world.

            Over the past 23 years we have grown to encompass three offices, including two strategically located storefronts located on the Upper West Side and Greenwich Village. We have more than 100 agents, many of whom have been with the firm for a decade or more. We also provide an in-house marketing team which allows us to take on a listing and immediately create property-specific marketing materials. Our adherence to a higher standard of professionalism and integrity is the driving force behind our long-term involvement on the national level with the National Association of REALTORS®, and locally with the Manhattan Association of REALTORS® and the Real Estate Board of New York.

FENWICK KEATS Management was created to work in tandem with FENWICK KEATS Real Estate to address the ongoing needs of our investor clients. We provide property management for over 60 buildings encompassing co-operatives, condominiums, rental buildings and commercial properties.

We believe that reputation is everything, and built ours by serving our clients. We're delighted to put our considerable resources to work for any of your real estate needs.
          }
        }
      end
    end
  end
end
