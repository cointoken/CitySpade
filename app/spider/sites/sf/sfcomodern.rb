module Spider
  module SF
    class Sfcommodern < Spider::SF::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '#content-primary-wrap #idx-results .idx-listing div ul li .info-links'
        @listing_agent_css = "#agent-details"
        @listing_image_css  = "#idx-detail-primary .thumbset ul li img"
        #@listing_callbacks[:image] =-> (img) {
        #}
      end

      def domain_name
        "http://www.sanfranciscomodern.com/"
      end

      def base_url
        domain_name + "idx/search.html"
      end

      def page_urls(opts={})
        urls = []
        66.times do |t|
          urls << [base_url + "?page=#{t+1}", 0]
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail doc, listing
        content = doc.css("#page #page-wrap #content")
        listing[:title] = content.css("#content-primary #idx-detail h1").text.split(",").first.strip
        listing[:price] = content.css("#content-primary #idx-detail #idx-detail-primary .price .val").text.gsub(/\D/, "")
        listing[:street_address] = content.css("#content-primary #idx-detail #idx-detail-primary .address .street .val").text.strip
        listing[:zipcode] = content.css("#content-primary #idx-detail #idx-detail-primary .city .val").text.split(" ").last.strip.gsub(/\D/, "")
        listing[:beds] = content.css("#content-primary #idx-detail #idx-detail-primary .beds .val").text.to_f
        listing[:baths] = content.css("#content-primary #idx-detail #idx-detail-primary .baths .val").text.to_f
        listing[:sq_ft] = content.css("#content-primary #idx-detail #idx-detail-primary .sqft .val").text.strip
        listing[:listing_type] = content.css("#content-primary #idx-detail #idx-detail-primary .type .val").text.strip if content.css("#content-primary #idx-detail #idx-detail-primary .type .val").text.strip != "-"
        listing[:description] = content.css("#content-primary #idx-detail #idx-detail-primary .remarks .val").text.strip

        retrieve_agents doc, listing
        retrieve_images doc, listing
        #retrieve_broker doc, listing
        listing[:contact_name] = listing[:agents].first[:name]
        listing[:contact_tel] = listing[:agents].first[:tel]

        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(@listing_agent_css).each do |agent_doc|
          agent = {}
          agent[:name] = agent_doc.css("#agent-details-info .agent-details-name").text.split("is available").first.strip
          agent[:tel] = agent_doc.css("#agent-details-info .agent-details-phone").text.split(",").first.gsub(/\D/, "")
          agent[:origin_url] = abs_url agent_doc.css("#agent-details-photo img").first.attr("src") if agent_doc.css("#agent-details-photo img").present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "San Francisco Modern Real Estate",
          tel: "",
          email: "",
          zipcode: "",
          website: domain_name,
          introduction: %q{
            Founded by one of the Bay Area's top-producing real estate agents with Keller Williams Realty (the 3rd largest residential real estate brokerage firm in the United States), San Francisco Modern Real Estate (DRE# 01836548) proudly represents buyers and sellers of residential properties in San Francisco, California.

Whether you are a first-time homebuyer or an experienced real estate investor, we would welcome the opportunity to serve you.   We work with clients that have extremely diverse budgets and architectural preferences and would welcome the chance to assist you with your Bay Area real estate needs.
          }
        }
      end

      def retrieve_images doc, listing
        imgdocs = doc.css(@listing_image_css)
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: imgdoc['src']} if imgdoc['src'].present?
        end
        listing
      end
    end
  end
end
