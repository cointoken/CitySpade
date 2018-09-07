class FsAPI
  BASE_URL = 'https://api.foursquare.com/v2/'
  cattr_accessor :categories
  def self.raw_get(api_name, opt={})
    opt = opt.merge(Settings.foursquare).merge(v: Time.now.strftime('%Y%m%d'))
    query = opt.to_query
    query.gsub!('%2C', ',')
    query.gsub!('%3A', ':')
    query.gsub!('%7C', '|')
    # query.gsub!('+', ' ')
    url = BASE_URL + api_name + "?#{query}"
    Rails.logger.info url
    RestClient.get url
  end

  def self.fresh_catygories
    FsCategory.upgrade
  end

  def self.search(name, opt, opt_2 = {})
    unless Hash === opt
      opt = {ll: "#{opt.lat},#{opt.lng}"}.merge opt_2
    end
    name = name.downcase
    opt.merge!(categoryId: FsCategory.get_ids_by_name(name).join(','))
    opt[:radius] ||= 400
    opt[:limit]  ||= 40
    opt[:venuePhotos] = 1
    group_by_name(Venue.array_to_obj(MultiJson.load(raw_get('venues/search', opt))['response']['venues']), name, limit: opt[:every_limit])
  end

  def self.multi_explore(name, opt, opt_2 ={})
    unless Hash === opt
      opt = {ll: "#{opt.lat},#{opt.lng}"}.merge opt_2
    end
    names = name.split('|')
    result = {}
    opt[:every_limit] ||=  2
    names.each{|n| result[n] = {
      'icon_url' => FsCategory.icon_url_by_name(n),
      'venues' => explore(n, opt.dup)}}
    result
  end

  def self.explore(name, opt, opt_2 = {})
    unless Hash === opt
      opt = {ll: "#{opt.lat},#{opt.lng}"}.merge opt_2
    end
    dont_again_flag = opt.delete :dont_again_flag
    default_radius = 1200
    name = name.downcase
    # opt.merge!(categoryId: FsCategory.get_ids_by_name(name).join(','))
    opt[:limit]  ||= 20
    opt[:query]  ||= name.titleize
    opt[:radius] ||= default_radius unless dont_again_flag
    opt[:venuePhotos] = 1
    every_limit = opt[:every_limit]
    json = MultiJson.load(raw_get('venues/explore', opt))
    if json['response']['totalResults'] < 2 && !dont_again_flag
      if opt[:radius] > default_radius
        opt.delete :radius
        opt[:dont_again_flag] = true
      else
        opt[:radius] = opt[:radius] * 5
      end
      return explore name, opt
    end
    arrs = Venue.array_to_obj json['response']['groups'].select{|s| s['name'] == 'recommended'}[0]['items'].map{|s| s['venue']}
    arrs = arrs.select{|s| s.is_same_category(opt[:query].downcase)}
    if every_limit
      result = []
      arrs.each do |arr|
        if result.size < every_limit && arr.photos.present?
          result << arr
        end
        break if result.size == every_limit
      end
      if result.size < every_limit && !dont_again_flag
        opt.merge every_limit: every_limit
        if opt[:radius] > default_radius
          opt.delete :radius
          opt[:dont_again_flag] = true
        else
          opt[:radius] = opt[:radius] * 5
        end
        return explore name, opt
      end
      result
    else
      arrs
    end
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

  class Venue
    attr_accessor :lat, :lng, :name, :id, :contact, :location, :categories, :raw, :description, :image_url, :rating, :distance
    def initialize(opt)
      @id = opt['id']
      @name = opt['name']
      @contact = opt['contact']
      @location = opt['location']
      @categories = opt['categories']
      @rating = opt['rating']
      @lat = @location['lat']
      @lng = @location['lng']
      @distance = @location['distance']
      @raw = opt
    end

    def image_url
      photos.first
    end
    def self.array_to_obj(arr)
      arr.map{|s| new(s)}
    end
    def photos(size = '210x160')
      @photos ||= begin
                    groups = detail['photos']['groups']# .map{|s| "#{s['prefix']}#{size}#{s['suffix']}"}
                    groups = groups.select{|s| s['type'] == 'venue'}
                    groups.map{|item| item['items'].map{|s| "#{s['prefix']}#{size}#{s['suffix']}"}}.flatten
                  end
    end
    def category_name
      @categories[0]['name'].downcase
    end

    def is_same_category(query)
      category_name.include? query
    end

    def detail
      @detail ||= begin
                    url = FsAPI::BASE_URL + "venues/#{id}?client_id=#{Settings.foursquare.client_id}" + \
                      "&client_secret=#{Settings.foursquare.client_secret}&v=#{Time.now.strftime("%Y%m%d")}"
                      Rails.logger.info url

                      MultiJson.load(RestClient.get(url))['response']['venue']# ['response']['photos']['items'].map{|s| "#{s['prefix']}#{size}#{s['suffix']}"}

                  end
    end
    def category_id
      @categories[0]['id']
    end

    def description
      @description ||= detail['description'] || begin
      items = detail['listed']['groups'][0]['items']
      if items.present?
        item = items[0]
        item['description']
      end
      end
    end
    def default_image_url
      'venues/venue_missing.jpg'
    end
  end
end
