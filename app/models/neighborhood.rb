class Neighborhood < ActiveRecord::Base
  default_scope -> { where('hot >= 0')}
  scope :city_by, ->(city) { where(city: city) }
  class << self
    def init_setup
      init_nyc
      init_philadelphia
      init_boston
    end
    def init_nyc
      Settings.neighborhoods.boroughs.each do |borough|
        borough.neighborhoods.each do |n|
          where(city: 'New York', borough: borough.name, name: n).first_or_create
        end
      end
    end
    ['philadelphia', 'boston', 'chicago'].each do |city|
      define_method "init_#{city}" do
        PoliticalArea.send(city).send(:neighborhoods).each do |n|
          ngh = where(city: city, name: n.long_name.split('/').first.strip).first_or_initialize
          ngh.hot += n.all_listings.count
          ngh.save
        end
        (city_by(city).order('hot desc')[60..-1]||[]).each do |ngh|
          ngh.update_attribute :hot, -1
        end
      end
    end
  end
end
