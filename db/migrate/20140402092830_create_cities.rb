class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :name, limit: 30
      t.string :state, limit: 20
      t.string :long_state, limit: 30
      t.string :country, limit: 20
      t.string :min_zip, limit: 7
      t.string :max_zip, limit: 7
      t.float :lat
      t.float :lng
      t.integer :hot 
    end
    add_index :cities, :name
    add_index :cities, :state
    add_index :cities, :hot
    require 'csv'
    path = File.join(Rails.root, 'db', 'cities.csv')
    arrs = CSV.read path
    opt = arrs.delete_at 0
    arrs.each do |row|
      city = {country: 'US'}
      row.each_with_index do |attr, i|
        city[opt[i]] = attr
      end
      city['name'] = city.delete 'city'
      zip = formatted_zip(city.delete 'zip')
      lat = city.delete 'lat'
      lng = city.delete 'lng'
      obj = City.where(city).first_or_create
      obj.lat ||= lat
      obj.lng ||= lng
      if obj.min_zip.blank? 
        obj.min_zip, obj.max_zip = zip, zip
      end
      obj.min_zip = zip if obj.min_zip > zip
      obj.max_zip = zip if obj.max_zip < zip
      obj.save
    end
    set_state_full_name
    init_cities_hot
  end
  def formatted_zip(zip)
    zip = zip.to_s
    if zip.size < 5
      zip = '0' * (5 - zip.size) + zip
    end
    zip
  end

  def set_state_full_name
    base_url = 'http://www.50states.com/abbreviations.htm'
    doc = Nokogiri::HTML(RestClient.get(base_url))
    states_hash = {}
    doc.css('.spaced.stripedRows tr').each do |tr|
      tds = tr.css('td')
      if tds.size == 2
        states_hash[tds.last.text.strip] = tds.first.text.strip
      end
    end
    states_hash.each do |key, value|
      City.where(state: key).update_all(long_state: value)
    end
  end

  def  init_cities_hot
    base_url = 'http://en.wikipedia.org/wiki/List_of_United_States_cities_by_population'
    doc = Nokogiri::HTML(RestClient.get(base_url))
    doc.css('.wikitable.sortable').first.css('tr').each do |tr|
      tds = tr.css('td')
      if tds.size == 10
        city = tds[1].css('a').first.text.strip || tds[1].text.strip
        state = tds[2].css('a').first.text.strip || tds[2].text.strip
        hot = tds[3].children.last.text.strip.gsub(/\D/, '').to_i
        latlngs = tds.last.text.strip.split(' ')
        lat = latlngs.first.split('°').first
        lng = 0 - latlngs.last.split('°').first.to_f
        if hot > 10
          City.where(name:city, long_state: state).update_all(hot: hot, lat: lat, lng: lng)
        end
      end
    end
  end
end
