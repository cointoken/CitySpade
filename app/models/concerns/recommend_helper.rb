module RecommendHelper
  # 推荐按三种情况：
  # 1.用户没有搜索过，按照位置给出
  # 2.用户搜索过1次，通过记录给出10条
  # 3.用户搜索过N次, 通过搜索过次数最多最新搜索的记录给出10条
  # 不够10条记录，通过用户当前位置给出分数最高的记录补上。
  def recommend_listings
    srs = self.search_records
    case srs.length
    when 0
      recommend_by_position
    when 1
      recommend_by_one_result(srs)
    else
      recommend_by_several_results(srs)
    end
  end

  def recommend_listings_by_access
    lls = []
    [1].each do |flag|
      opts = get_opts_by_access(flag)
      if opts[:political_area_id].present?
        min_price = opts.delete :min_price
        max_price = opts.delete :max_price
        dont_ids = opts.delete :dont_ids
        tmp_lls = Listing.enables.where(political_area_id: opts[:political_area_id]).where(flag: flag).order('is_full_address desc, listing_image_id is not null desc, id desc')
        tmp_lls = tmp_lls.where("id not in (#{dont_ids.join(',')})")
        tmp_lls = tmp_lls.where('created_at > ?', Time.now - 15.day)
        tmp_lls = tmp_lls.where("price >= ? and price <= ?", min_price, max_price).limit 6
        lls << tmp_lls.to_a
      end
    end
    lls.flatten
  end

  def dummy_listings
    # used to test MailPreview.recommend
    # lib/mailer_previews/mail_preview.rb
    Listing.limit(6)
  end

  private
  def recommend_by_position
    searching_listings_from_db({})
  end

  def recommend_by_one_result(result)
    searching_listings_from_db(result)
  end

  def recommend_by_several_results(results)
    searching_listings_from_db(results.order(re_search_num: :asc, created_at: :asc).last)
  end

  def searching_listings_from_db(result)
    result = result.slice(:title, :flag, :beds, :baths, :current_area) unless result.blank?
    area = current_area(result)
    recommend = Listing.custom_search(area, result).where('created_at > ?', Time.now - 1.day).limit(10)
    if recommend.length < 10
      surplus = Listing.custom_search(area, {custom_order: "score_price desc"}).where('created_at > ?', Time.now - 1.day).limit(10 - recommend.length)
      recommend.concat(surplus)
    end
    recommend
  end

  def current_area(result)
    if result[:current_area]
      PoliticalArea.where(target: 'locality', long_name: result[:current_area].gsub('-',' ')).first ||
        PoliticalArea.default_area
    else
      if current_city && current_city.state == 'PA'
        PoliticalArea.philadelphia
      else
        PoliticalArea.default_area
      end
    end
  end

  def current_city
    geoip = Geokit::Geocoders::MaxmindGeocoder::geocode(self.last_sign_in_ip)
    geoip = Geokit::Geocoders::IPApiGeocoder.geocode self.last_sign_in_ip if !geoip.success? || (geoip.city.blank?)
    City.where(name: geoip.city, long_state: geoip.state, country: "US").first
  end

  def get_opts_by_access(flag = 0)
    opts = {}
    listings = Listing.where(id: self.page_views.where(page_type: 'Listing').where('updated_at > ?', Time.now.months_ago(1)).map(&:page_id)).where(flag: flag)
    opts[:dont_ids] = listings.map(&:id)
    opts[:political_area_id] = listings.group(:political_area_id).count.to_a.sort{|x, y| y[1] <=> x[1]}.map{|s| s[0]}[0..3]
    opts[:political_area_id] = opts[:political_area_id].map{|s| PoliticalArea.find(s).sub_ids(include_self: true)}.flatten
    mid_price = listings.average(:price)
    if mid_price && mid_price > 0
      min_price = [[mid_price - listings.order(price: :asc).first.price / 2, mid_price * 2 - listings.order(price: :desc).first.price * 1.5].max, mid_price * 2 / 3].min
      max_price = 2 * mid_price - min_price
      opts[:min_price], opts[:max_price] = min_price, max_price
    end
    beds = listings.group(:beds).count.to_a.sort{|x, y| y[1] <=> x[1]}.map{|s| s[0]}.reject(&:blank?)[0..1]
    baths = listings.group(:baths).count.to_a.sort{|x, y| y[1] <=> x[1]}.map{|s| s[0]}.reject(&:blank?)[0..1]
    opts[:beds] = beds if beds
    opts[:baths] = baths if baths
    opts
    #listings.group(:beds).cout
  end
end
