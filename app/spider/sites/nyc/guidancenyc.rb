module Spider
  module NYC
    class Guidancenyc < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".intrinsic a"
        @listing_image_css = ".sqs-gallery-thumbnails img"
      end 

      def domain_name 
        'http://www.guidancenyc.com/'
      end

      def page_urls(opt = {})
        [['http://www.guidancenyc.com/', 1]]
      end

      def get_listing_url simple_doc
        abs_url simple_doc['href']
      end

      def retrieve_detail doc, listing
        content = doc.css(".sqs-block-content")[0].css("strong")
        detail = []
        content.map{|e| detail << e.text if e.text.present?}
        opts = detail[0].split("#")
        listing[:title] = opts[0].remove(/\W{2,}/).strip
        listing[:unit] = opts[1].strip if opts[1].present?
        listing[:price] = detail[1].remove(/\D/)
        rooms = detail[2].split(",")
        listing[:beds] = rooms[0].to_f if rooms[0].match(/Bed/)
        listing[:baths] = rooms[1].to_f if rooms[1].match(/Bath/)
        description = doc.css(".col.sqs-col-5.span-5").text.split("AMENITIES")[0]
        listing[:description] = description
        obj = nil
        listing[:amenities] = amenities doc, obj
        retrieve_agents doc, listing
        retrieve_broker doc, listing
        listing[:contact_tel] = listing[:agents][0][:tel] 
        listing[:contact_name] = listing[:agents][0][:name]
        listing
      end

      def amenities doc, obj
        div = doc.css(".col.sqs-col-5.span-5 .sqs-block-content")
        div.children.reverse.each do|child|
          if child.name == "ul" 
            obj = child.css("li").map{|amen| amen.text.strip}.delete_if{|t| t.blank?}
          elsif child.name == "h2"
            break
          end
        end
        obj
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Guidance Realty NYC",
          tel: "2125952300",
          email: "rentals@guidancenyc.com"
        }
      end

      def retrieve_agents doc, listing
        agents = []
        agent = {}
        agent_content = doc.css(".sqs-block-content")[3]
        if agent_content.children[1].children.size == 1
          agent[:name] = agent_content.children[1].text.strip
          if agent_content.children[2].text.match(/@/)
            agent[:email] = agent_content.children[2].text.strip 
            agent[:tel] = agent_content.children[3].text.remove(/\D/)
          else
            agent[:tel] = agent_content.children[2].text.remove(/\D/)
          end
        else
          agent_content_text = agent_content.children[1].children.map {|c| c.text.strip}.reject &:blank?
          agent[:name] = agent_content_text[0]
          agent[:email] = agent_content_text[1] 
          agent[:tel] = agent_content_text[2].remove(/\D/)
        end
        agents << agent
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_images(doc, listing, opt={})
        return nil if listing.blank?
        listing[:images] = []
        images = doc.css(@listing_image_css)
        images.each do|img|
          listing[:images] << {origin_url: img.attr("data-src")} if img.attr("data-src").present?
        end
        listing
      end
    end
  end
end