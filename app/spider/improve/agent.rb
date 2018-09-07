module Spider
  module Improve
    class Agent
      class << self
        def corcoran(doc, obj)
          basic = doc.css('#agent-bio .wallet-info').first
          if doc
            obj[:name] = basic.css('.info .name').text.strip.gsub(/\s+/, ' ')
            obj[:email] = basic.css('.info .AgentBioEmail').text.strip
            office = basic.css('.info li').select{|s| s.text.include?('Office')}.first
            obj[:office_tel] = office.text.gsub(/\D/, '') if office
            fax    = basic.css('.info li').select{|s| s.text.include?('Fax')}.first
            obj[:fax_tel] = fax.text.gsub(/\D/, '') if fax
            # obj[:origin_url] = basic.css('.picContainer img').first.try '[]', 'src'
            obj[:introduction] = doc.css('#agent-bio-content .bio-writeup p').text.strip
          end
          obj
        end

        def aptsandlofts(doc, obj)
          obj[:introduction] = doc.css("#right-rail p").text.strip
          obj[:name] = doc.css('.contact li strong').text.strip.gsub(/\s+/, ' ')
          doc.css("ul.contact").text.split("\n").reject(&:blank?).map(&:strip).each do |li|
            obj[:office_tel] = li.gsub(/\D/, "") if li.match(/O\:\s/)
            obj[:fax_tel] = li.gsub(/\D/, "") if li.match(/F\:\s/)
            obj[:address] = li.strip if li.match(/\d{2,}\s\w/)
            obj[:email] = li.strip if li.match(/\@/)
          end
          obj
        end

        def elliman(doc, obj)
          obj[:introduction] = doc.css('._grid28._alpha .wysiwyg').text.strip
          # obj[:name] = doc.css(".wysiwyg .black strong").text.strip.gsub(/\s+/, " ")
          links = doc.css(".wysiwyg p a")
          email_url = nil
          if links.present?
            links.each do |link|
              email_url = link.attr("href") if link.text.match(/Email/).present?
            end
            if email_url.present?
              email_url.gsub!(/\A\#/, "")
              email_url = "http://www.elliman.com" + email_url if email_url.match(/http\:/).blank?
              res = RestClient.get(email_url)
              email = Nokogiri.HTML(res).css(".\\\"w_lstagt_email\\\"").text.strip.split("\\n").first
              obj[:email] = email.gsub(/[\<\>]/,"").strip if email.present? and email.match(/@/)
            end
          end
          obj
        end

        def kwnyc(doc, obj)
          obj[:introduction] = doc.css('#fBio').text.strip
          obj[:name] = doc.css(".textRight h1").text.strip.gsub(/\s+/, " ")
          obj[:mobile_tel] = doc.css('#agentMobile').text.gsub(/\D/, "").strip
          contents = doc.css(".textRight p").first.text.split("\r\n").reject{|o| o.blank? }
          contents.each do |con|
            obj[:address] = con.split("|").first.strip if con.match(/\|/)
            obj[:email] = con.strip if con.match(/\@/)
          end
          obj
        end

        def halstead(doc, obj)
          obj[:introduction] = doc.css('.lang-en').text.strip
          obj[:name] = doc.css(".agent-bar .photo-bar h2").text.strip.gsub(/\s+/, " ")
          doc.css(".agent-detail a").each do |detail|
            obj[:email] = detail.text.strip if  detail.text.match(/@/).present?
          end
          obj
        end

        def citihabitats(doc, obj)
          obj[:introduction] = doc.css('#long_descr').text.strip
          obj[:name] = doc.css(".agent_title").text.gsub(/\s+/, " ").strip
          doc.css(".agent_info").text.split("\n").reject{|o| o.blank? }.each do |detail|
            if detail.match(/\:\s\d{3}/)
              tels = detail.gsub(/\D/, "").split("|")
              tels.each do |tel|
                obj[:office_tel] = tel.strip.gsub(/\D/, "") if tel.match(/O:/i)
                obj[:fax_tel] = tel.strip.gsub(/\D/, "") if tel.match(/F:/i)
              end
            end
          end
          obj
        end
        def mns(doc, obj)
          obj[:introduction] = doc.css('.height2').text.strip
          obj[:name] = doc.css(".heading .text-container h2").text.strip.gsub(/\s+/, " ")
          obj[:email] = doc.css(".email-link").attr("href").value.gsub(/mailto\:/, "")
          tels = doc.css(".info-box .row dl").text.strip.split("\r\n").map(&:strip)
          tels.each_with_index do |tel, index|
            obj[:office_tel] = tels[index+1].gsub(/\D/, "") if tel.match(/o\:/)
            obj[:fax_tel] = tels[index+1].gsub(/\D/, "") if tel.match(/f\:/)
          end
          obj
        end
        def bhsusa(doc, obj)
          obj[:introduction] = doc.css('.lang-en').text.strip
          obj
        end
        def nestseekers(doc, obj)
          obj[:introduction] = doc.css('#bio').text.strip
          obj[:name] = doc.css(".userMenuContent .title").text.strip.gsub(/\s+/, " ")
          obj[:name] = doc.css(".userMenuContent h1.title").text.strip.gsub(/\s+/, " ")
          doc.css("#agent-top div").text.split(/\n\t/).reject{|a|a.blank?}.each do |detail|
            obj[:address] = detail.strip if detail.match(/\A\d{2,}\s\w/)
          end
          obj
        end
        def townrealestate(doc, obj)
          obj[:introduction] = doc.css('#fullBio').text.to_utf8.strip
          obj[:name] = doc.css(".agentname h1").text.strip.gsub(/\s+/, " ")
          doc.css(".box-content div div div").text.split("\n\t").reject(&:blank?).map(&:strip).each do |detail|
            obj[:office_tel] = detail.gsub(/\D/,"") if detail.match(/O\:\s/)
            obj[:fax_tel] = detail.gsub(/\D/,"") if detail.match(/F\:\s/)
            obj[:address] = detail.split(",")[0].strip if detail.match(/\A\d{2,}/)
            obj[:email] = detail if detail.match(/\@/)
          end
          obj
        end

        def fenwickkeats(doc, obj)
          obj[:introduction] = doc.css('FullBio').text.to_utf8.strip
          obj[:name] = doc.css('#agentAmazingness #AgentName span').text.strip
          doc.css("#AgentContent #agentSpecs span").each do |detail|
            obj[:office_tel] = detail.gsub(/\D/,"") if detail.text.match(/M\:\s/)
            obj[:email] = detail if detail.text.match(/\@/)
          end
          obj
        end

        def rutenbergrealtyny
          obj[:introduction] = doc.css('.agent-bio').text.to_utf8.strip
          obj[:name] = doc.css('.agent-info .page-titlen').text.strip
          doc.css(".agent-info .contact-info span").each do |detail|
            obj[:office_tel] = detail.text.split(/x/i).first.gsub(/\D/,"") if detail.text.match(/o\:\s/i)
            obj[:mobile_tel] = detail.text.split(/x/i).first.gsub(/\D/, "") if detail.text.match(/m\:\s/i)
          end
          obj
        end

        def realty_mx(doc, obj)
          site = obj[:website].match(/http:\/\/(.+)\.com/)
          case site
          when "calibernyc"
            obj[:introduction] = doc.css('.overview').text.strip
          when "bouklisgroup", "sovereignrealestate"
            obj[:introduction] = doc.css('td.col2').text.strip
          when "rentmanhattan", "lsany"
            obj[:introduction] = doc.css('td.col2 p').text.strip
          when "hechtgroup"
            obj[:introduction] = doc.css('.agentBio').text.strip
          when "manhattanconnection"
            obj[:introduction] = doc.css('#long-text').text.strip
          else
            obj[:introduction] = doc.css('#agentProfile-bio').text.strip
          end
          obj
        end
      end
    end
  end
end
