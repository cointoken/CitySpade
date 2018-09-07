module Spider
  module Improve
    class Image
      @@site_classes = {}
      PROC_IMG = {
        'Spider::NYC::Base' => ['bhsusa', 'citi_habitats', 'corcoran', 'elliman', 'halstead', 'kwnyc', 'mns', 'nestseekers', 'townrealestate', 'aptsandlofts'],
        'Spider::Philadelphia::Base' => ['maxwellrealty', 'allandomb', 'phillyapartmentco'],
        'Spider::Boston::Base' => ['blueskyboston', 'bushari', 'campionre', 'centrerealtygroup', 'properrg', 'speedhatch']
      }
      class << self
        PROC_IMG.each do |pclass_s, sites|
          sites = pclass.subclasses.map{|s|s.to_s.split('::').last.downcase} if sites.blank?
          sites.each do |key|
            define_method key do |doc, listing|
              pclass = eval pclass_s
              listing ||= nil
              if key == 'citi_habitats'
                classify = 'CitiHabitats'
              elsif key == 'nestseekers'
                classify = 'NestSeekers'
              elsif key == 'aptsandlofts'
                classify = 'Aptsandlofts'
              else
                classify = key.classify
              end
              cls = @@site_classes[classify] || begin
              c = pclass.descendants.select{|s| s.to_s.include?(classify)}.first
              if c 
                @@site_classes[classify] = c
              end
              c
              end
              if cls
                cls.new.retrieve_images(doc, listing)
              end
            end
          end
        end
      end
    end
  end
end
