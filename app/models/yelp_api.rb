class YelpAPI
  def self.connection
    @@connection ||= Yelp::Client.new Settings.yelp
  end

  def self.group_by_name(arrs, name, opt={})
    names = name.split('|')
    result = {}
    opt[:every_limit] ||= 2
    names.each{|n| result[n] = {'icon_url' => FsCategory.icon_url_by_name(n), 'venues' => []}}
    arrs.each do |arr|
      names.each do |n|
        if arr.category_name.include?(n) && result[n]['venues'].size < opt[:every_limit]
          if arr.photos.present?
            result[n]['venues'] << arr 
          end
        end
      end
    end
    result
  end
  def self.multi_search(names, opt, opt_2 = {})
    results = {}
    names.split('|').each{|name| results[name] = search(name, opt, opt_2)}
    results
  end

  def self.term_to_category(name)
    {
      laundry: 'drycleaninglaundry',
      restaurant: 'restaurants'
    }[name.to_sym] || name

  end
  def self.search(name, opt, opt_2 ={})
    unless Hash === opt
      opt = {latitude: opt.lat, longitude: opt.lng}.merge opt_2
    end
    opt[:latitude] ||= opt.delete :lat
    opt[:longitude] ||= opt.delete :lng
    name = name.downcase
    result = {'icon_url' => FsCategory.icon_url_by_name(name), 'venues' => []}
    defualt_radius_filter = 1200
    # defualt_radius_filter *= 2.5 if name == 'parking'
    limit_num = opt.dup.delete(:limit_num) || 2
    i = 0
    begin
      if i > 3
        res = connection.search_by_coordinates(opt, term: name, category_filter: term_to_category(name))
      else
        res = connection.search_by_coordinates(opt, term: name, category_filter: term_to_category(name), radius_filter: defualt_radius_filter * 2 ** i)
      end
      i += 1
    end while i < 4 && res.businesses.select{|s| s.try(:image_url).present?}.size < limit_num
    if res
      res.businesses.select{|s| s.is_full_burst?(name)}.each do |business|
        if result['venues'].size < limit_num
            result['venues'] << business
        else
          break
        end
      end
    end
    result['venues'].sort!{|x, y| x.distance <=> y.distance}
    result
  end
end
class BurstStruct::Burst
  def description
    snippet_text
  end
  def default_image_url
    'venues/venue_missing.jpg'
  end #default_image_url
  def l_image_url
    image_url.sub(/ms\.jpg$/, 'ls.jpg').sub(/^http\:/, 'https:')
  end
  def connection_url
    url && url.sub(/^http\:/, 'https:')
  end
  def is_full_burst?(name = nil)
    @hash['image_url'] && @hash['snippet_text'] && @hash['rating_img_url'] 
  end
end
