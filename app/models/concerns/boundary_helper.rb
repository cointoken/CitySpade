module BoundaryHelper
  def self.included(base)
    base.extend ClassMethods 
  end
  def coordinates
    @coordinates ||= begin
                       return [] if self.city.long_name != 'New York'
                       feature = PoliticalArea.boundaries['features'].select{|s| s['properties']['label'] == self.long_name }.first
                       if feature.present?
                         feature['geometry']['coordinates']
                       else
                         []
                       end
                     end
  end
  module ClassMethods
    def boundaries
      @boundaries_hash ||= MultiJson.load File.read(Rails.root.join('db', 'boundaries.json'))
    end
  end
end
