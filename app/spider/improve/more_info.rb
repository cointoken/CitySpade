module Spider
  module Improve
    class MoreInfo
      PROC_MOREINFO = {
        'corcoran' => ->(doc){
          hash = {}
          info = doc.css('#listing-info .content-rail').first
          if info
            linfo = info.css('.essentials li')
            if linfo && price = linfo.first && price.text.downcase.include?('price')
              hash[:price] = price.text.gsub(/\D/, '')
            end

            if linfo && br = linfo[2] && br.text.downcase.include?('bedroom')
              hash[:beds] = br.text.gsub(/\D/, '')
            end
            if linfo && bt = linfo[3] && bt.text.downcase.include?('bath')
              hash[:baths] = bt.css('span').first.text
            end
            agent = info.css('.agent-card')
            if agent
              if contact_name = agent.css('span.title').first && contect_tel = agent.css('span.contact').first
                hash[:contact_name] = contact_name.text.strip
                hash[:contact_tel]  = contect_tel.text.gsub(/\D/, '')
              end
            end
          end
          Spider::NYC::Corcoran.new.get_detail(doc, hash)
          hash.delete :images
          hash
        },
        'elliman' => ->(doc){
          hash = {}
          info = doc.css('.w_listitem_description').first
          if info
            if price = info.css('.listing_price').first
              hash[:price] = price.text.gsub(/\D/, '')
            end
            if brt = info.css('.listing_features').first
              bs = brt.text.split('|')
              ['beds', 'baths'].each_with_index do |attr,i|
                if bs[i].include?(attr)
                  hash[attr.to_sym] = bs[i].gsub(/#{attr}/i, '')
                end
              end
            end
            agent = doc.css('.w_listitem_agent_info').first
            if agent
              if tel = agent.css('.tel').first
                hash[:contact_tel] = tel.text.gsub(/\D/,'')
              end
              if name = agent.css('.n').first
                hash[:contact_name] = name.text
              end
            end
          end
          Spider::NYC::Elliman.new.get_detail(doc, hash)
          hash
        },
        'bhsusa' => ->(doc){
          hash = {}
          Spider::NYC::Bhsusa.new.get_detail(doc, hash)
          hash.delete :images
          hash
        },
        'nestseekers' => ->(doc){
          hash = {}
          agent = doc.css('#agent .tight')
          if agent
            if name = agent.css('a').first
              hash[:contact_name] = name.text.strip
            end
            if tel = agent.css('div')[3]
              if tel.text.downcase.include?('mobile')
                hash[:contact_tel] = tel.text.gsub(/\D/,'')
              end
            end
          end
          Spider::NYC::NestSeekers.new.get_detail(doc, hash)
          hash
        },
        'kwnyc' => ->(doc){
          hash = {}
          Spider::NYC::Kwnyc.new.get_detail(doc, hash)
          hash.delete :images
          hash
        },
        'citi_habitats' => ->(doc){
          hash = Spider::NYC::CitiHabitats.new.retrieve_listing(doc)
          unless hash.is_a?(Hash)
            hash = {}
          else
            hash.delete :images
            hash.delete :url
          end
          hash
        },
        'townrealestate' => ->(doc){
          hash = {}
          Spider::NYC::Townrealestate.new.retrieve_detail(doc, hash)
          hash
        },
        'halstead' => ->(doc){
          hash = {}
          Spider::NYC::Halstead.new.get_detail(doc, hash)
          hash.delete :images
          hash
        },
        'aptsandlofts' => ->(doc){
          hash = {}
          Spider::NYC::Aptsandlofts.new.retrieve_detail(doc, hash)
          hash
        }
      }
      class << self
        PROC_MOREINFO.each do |key,value|
          define_method key do |doc, opt={}|
            value.call(doc)
          end
        end
        ['maxwellrealty', 'allandomb', 'phillyapartmentco'].each do |site|
          define_method site do |doc, opt={}|
            hash = opt
            Spider::Philadelphia.const_get(site.classify).new.retrieve_detail(doc, hash)
            hash
          end
        end
        ['blueskyboston', 'bushari', 'campionre', 'centrerealtygroup', 'properrg', 'speedhatch'].each do |site|
          define_method site do |doc, opt={}|
            hash = opt
            Spider::Boston.const_get(site.classify).new.retrieve_detail(doc, hash)
            hash
          end
        end
      end
    end
  end
end
