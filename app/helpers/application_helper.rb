module ApplicationHelper

  def equal_is_active(item, other_item)
    item == other_item ? 'active' : ''
  end

  def bed_options
    beds = [['Any Beds', nil]]
    beds << ['STUDIO', 0]
    (1..3).each do |n|
      beds << [n, n]
    end
    beds << ["4+", 4]
    beds
  end

  def search_area_options
    Settings.cities.values.map do |city|
      [city['long_name'] == 'New York' ? 'New York City' : city['long_name'], city['long_name'].to_url]
    end
  end

  def bath_options
    baths = [['Any Baths', nil]]
    (1..3).each do |n|
      baths << [ n * 0.5, n * 0.5]
    end
    baths << ["2+", 2]
    baths
  end

  def display_distance(obj, type=nil)
    if obj.respond_to? :distance
      distance = obj.distance
    else
      distance = obj.to_i
    end
    return '0 foot' if distance.blank? || distance == 0
    type != "neighborhood_talk" ? ml = (distance / 1609.0).round(1) : ml = (distance / 1609.0).round(2)
    if ml > 0.1
      return "#{ml} #{ml > 1 ? 'miles' : 'mile'}"
    end
    "#{(distance / 0.3048).to_i} feet"
  end

  def display_duration(obj)
    if obj.duration.present?
      "#{obj.duration / 60} mins"
    else
      '0 min'
    end
  end

  def display_to_url(url)
    if url.present?
      url
    else
      'javascript:void(0);'
    end
  end

  def display_tel(listing)
    if String === listing
      "(#{listing[0..2]}) #{listing[3..5]}-#{listing[6..9]}"
    else
      if listing.contact_name != 'Maxwell Realty Company' && !listing.can_find_tel? && listing.origin_url#!listing.can_find_tel_by_brokers? && listing.is_mls?
        link_to 'Click for original post', listing.origin_url, target: '_blank', class: 'tel-view-at-broker-site'
      else
        if listing.broker.try(:name) == listing.contact_name && listing.broker.try(:tel).present?
          "(#{listing.broker.tel[0..2]}) #{listing.broker.tel[3..5]}-#{listing.broker.tel[6..9]}"
        elsif listing.contact_tel.present?
          "(#{listing.contact_tel[0..2]}) #{listing.contact_tel[3..5]}-#{listing.contact_tel[6..9]}"
        else
          ''
        end
      end
    end
  end


  def display_contact_name(name)
    if name.present?
      truncate(name, length: 28, separator: ' ')
    end
  end

  def display_contact_tel(phone_number)
    if phone_number.present?
      "(#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..9]}"
    else
      ''
    end
  end

  def display_score(listing, target = :score_price)
    if listing.send(target).present? && (target != :score_price || listing.price <= 10000)
      "#{sprintf("%.2f",listing.send(target))}/10"
    elsif target == :score_price && listing.price > 10000 && listing.flag == Settings.flags.rental
      content_tag(:strong, 'Luxury', class: 'luxury')
    else
      "---"
    end
  end

  def building_address(listing, target = :long_name)
    "#{listing.address}"
  end

  def building_title(listing)
    "#{listing.name}"
  end

  def full_neighborhood(listing, target = :long_name)
    "#{listing.real_neighborhood(target)}, #{listing.state.try :short_name}, #{listing.zipcode}"
  end

  def display_beds_and_baths(listing)
    "#{display_bedrooms(listing)},
    #{display_baths(listing)}#{display_sq_ft(listing) != nil ? ', ' + number_with_delimiter(listing.sq_ft.to_i).to_s + ' ft²' : nil}"
  end

  def to_integer(float)
    float % 1 == 0 ? float.to_i : float
  end

  def display_beds(listing)
    if listing.beds > 1
      listing.beds.to_s + " Beds"
    elsif listing.beds == 0
      'Studio'
    else
      listing.beds.to_s + " Bed"
    end
  end

  def display_sq_ft(listing)
    if listing.sq_ft && listing.sq_ft > 0
      number_with_delimiter(listing.sq_ft.to_i).to_s + " ft²"
    end
  end

  def display_price_per_sq_ft(listing)
    if listing.sq_ft && listing.flag == 0
      price = listing.price / listing.sq_ft
      "$" + price.to_i.to_s + " per ft²"
    end
  end

  def display_bedrooms(listing)
    case num = listing.beds.to_i
    when 0
      'Studio'
    when 1
      num.to_s + " Bedroom"
    else
      num.to_s + " Bedrooms"
    end
  end

  def seo_for_title(listing)
    return unless listing
    str = ''
    if action_name == "show"
      str << 'NO-FEE '  if listing.no_fee
      str << display_bedrooms(listing).gsub(/s$/, '')
      str << ' '
      if listing.formatted_address.present?
        str << ["for #{listing.flag_name} in #{listing.display_title}", listing.formatted_address.split(',')[1..-2].map(&:strip)].join(', ')
      else
        str << ["for #{listing.flag_name} in #{listing.display_title}", listing.neighborhood_name, listing.state.try(:short_name), listing.zipcode].join(', ')
      end
    end
    str
  end

  def seo_keywords
    @page_keywords || begin
    keys = ['CitySpade']
    if ['listings', 'reviews', 'blog'].include? controller_name
      keys << controller_name.classify
      if action_name == 'show'
        obj = @listing || @review || @blog
        keys << obj.political_area.try(:long_name)
        keys << obj.try(:title)
      end
    end
    keys.join(',')
    end
  end

  def seo_description
    @page_description || if @listing && controller_name == 'listings'
    seo_description = seo_for_title(@listing)
    seo_description << ". " << text_content(@listing.listing_detail.try(:description), 160-title.length).gsub('&#39;', "'")
    elsif !@review.try(:title).nil? && controller_name == 'reviews'
      "Ratings and reviews for #{@review.title}. #{text_content(@review.comment, 160 - @review.title.length).gsub('&#39;', "'")}"
    elsif @blog
      text_content(@blog.content, 200)
    elsif @room && controller_name == 'rooms'
      seo_description = "#{@room.title}:Find rooms for rent and roommates in New York city | Cityspade"
    elsif @roommate && controller_name == 'roommates'
      seo_description = "#{@roommate.title}:Find rooms for rent and roommates in New York city | Cityspade"
    else
      "Make smarter rental decisions through our building and neighborhood reviews. CitySpade is here to help you with your apartment search in New York City."
    end
  end

  def display_baths(listing)
    listing.baths ||= 0
    bath_number = listing.baths % 1 == 0 ? listing.baths.to_i : listing.baths
    if bath_number > 1
      bath_number.to_s + " Baths"
    else
       "1 Bath"
    end
  end

  def collect_listing_link(listing, html_options = {}, &block)
    new_html_options = html_options.merge({remote: true}).merge(id: "collect-listing-#{listing.id}-box")
    if current_account.try('collect?',listing)
      link_to uncollect_listing_path(listing), new_html_options.merge(class: 'collected') do
        yield
      end
    else
      link_to collect_listing_path(listing), new_html_options.merge(class: 'uncollect') do
        yield
      end
    end
  end

  #def collect_listing_link(listing, icon="", text="")
  #  if current_account.try('collect?',listing)
  #    link_to uncollect_listing_path(listing, collect_text: text), remote: true do
  #      if icon.present?
  #        content_tag :i, class: "#{icon} collected" do
  #        end.+ raw text
  #      else
  #        raw text
  #      end
  #    end
  #  else
  #    link_to collect_listing_path(listing, collect_text: text), remote: true do
  #      if icon.present?
  #        content_tag :i, class: "#{icon} uncollected" do
  #        end.+ raw text
  #      else
  #        raw text
  #      end
  #    end
  #  end
  #end

  def listing_default_image_url(target=nil)
    case target
    when :rand
      image_url("covers/0#{rand(6) % 6 + 1}.jpg")
    else
      image_url('default.jpg')
    end
  end

  def listing_image_url(listing, size='360X240', target = nil)
    listing.image_url(size) || listing_default_image_url(target)
  end

  def google_maps_script(callback=nil, query_str='')
    raw(javascript_include_tag("https://maps.googleapis.com/maps/api/js?sensor=true#{query_str}&client_id=gme-cityspade") +
        javascript_include_tag('maps/init')).concat(content_tag(:script, type: 'text/javascript') do
      callback.present? ? "#{callback}();" : ''
    end)
  end

  def title
    return @title if @title
    case controller_name.downcase
    when 'listings'
      tl = seo_for_title(@listing)
    when 'blogs'
      tl = "#{@blog.try(:title)}"
    when 'search'
      tl = "Search Listing for #{params[:flag]}"
    when 'reviews'
      case action_name
      when 'index'
        tl = 'Reviews'
      when 'new'
        tl = 'Write a review'
      when 'show'
        tl = "#{@review.try :title} Reviews"
      end
    end
    tl
  end

  def full_title
    @page_title || begin
    base_title = 'CitySpade'
    if title.present?
      "#{title} | #{base_title}"
    else
      base_title
    end
    end
  end

  def share_link(social, url = nil)
    case social
    when 'facebook'
      if controller_name == 'blogs'
        url = full_url.split('-').first
      else
        url = full_url
      end if url.blank?
      "https://www.facebook.com/sharer/sharer.php?u=#{url}"
    when 'twitter'
      "https://twitter.com/share?url=#{full_url}&text=#{@listing.try(:title) || @blog.try(:title)}"
    when 'pinterest'
      "http://pinterest.com/pin/create/button/?url=#{full_url}&media=#{@listing.try(:image_url,'300X246') || asset_url('default_blog.jpg')}"
    else
      '#'
    end
  end

  def full_url
    request.url.sub(/^http\:/, 'https:')
  end

  def nav_link(link_text, link_path)
    class_name = (current_page?(link_path) ||
                  begin
                    link_path.to_s.underscore.include? action_name
    end) ? 'current' : nil
    content_tag(:li, :class => class_name) do
      link_to link_text, link_path
    end
  end

  def has_review_in_city?
    Review.has_review_in_city?(current_city)
  end

  def city_name_by_current_area
    if current_area.long_name == 'New York'
      'New York City'
    else
      current_area.long_name
    end
  end

  def current_account_own?(item)
    current_account.present? and item.respond_to?(:account) and item.account == current_account
  end

  def admin?
    current_account && current_account.admin?
  end

  def render_cities_btn(opt={})
    str = ''
    Settings.cities.each_with_index do |city, index|
      city = city.last
      city_long_name = city['long_name'] == "New York" ? "New York City" : city['long_name']
      if block_given?
        yield(city_long_name, city, index)
      else
        href = opt[:href] || send(opt[:href_method], city['long_name'].to_url) if opt[:href] || opt[:href_method]
        data_target_url = href || "/search/#{city['long_name'].to_url}/"
        href = data_target_url if opt[:direct_href]
        href ||= 'javascript:void(0);'
        class_name = opt[:class] || "current-area-link"
        class_name += " #{opt[:active_class] || 'active'}" if current_area.long_name == city['long_name']
        str += link_to city_long_name, href, class: class_name, data: {target_url: data_target_url, current_area: city['long_name'] }
      end
    end
    raw str
  end
  def render_tmpl
    if @tmpl_name
      render @tmpl_name
    end
  end
  def text_content(content, len = 300)
    truncate(strip_tags(content || ''), length: len, separator: ' ')
  end

  def search_review?
    !!session[:s_r]
  end

  def render_rebots_status
    if Rails.env == 'staging'
      return content_tag :meta, nil, name: 'robots', content: 'noindex, nofollow'
    end
    if controller_name == 'search' && !(search_neighborhood_name && params[:page].blank?)
      return content_tag :meta, nil, name: 'robots', content: 'noindex, follow'
    end
    if action_name == 'show'
      instance = eval "@#{controller_name.singularize}"
      if instance && instance.respond_to?("is_enable?")
        if (controller_name == 'listings' && !instance.is_enable?(true)) || !instance.is_enable?
          return content_tag :meta, nil, name: 'robots', content: 'noindex'
        end
        if controller_name == 'reviews' && @venue && @venue.reviews == 0
          return content_tag :meta, nil, name: 'robots', content: 'noindex'
        end
      elsif controller_name == 'reviews' && @venue && @venue.reviews == 0
        return content_tag :meta, nil, name: 'robots', content: 'noindex'
      elsif controller_name == 'agents'
        if params[:page] && params[:page].to_i > 1
          return content_tag :meta, nil, name: 'robots', content: 'nofollow, noindex'
        else
          return content_tag :meta, nil, name: 'robots', content: 'index, nofollow'
        end
      end
    end
  end

  def link_to_review obj, title=nil, opt={}, &block
    title ||= display_review_title(obj)
    if Review === obj# .id == review.venue.reviews.last.id
      path = venue_review_path(obj.venue_param)#venue_url(review.venue_param.slide)
    else
      path = venue_path(obj.review_param)
    end
    link_to title, path, opt, &block
  end

  def render_link_canonical
    if controller_name == 'reviews'
      if action_name == 'show' && @review
        content_tag :link, nil, rel: 'canonical', href: venue_url(@review.venue_param.slice(:review_type, :permalink))
      elsif action_name == 'new'
        content_tag :link, nil, rel: 'canonical', href: new_review_url
      end
    end
  end

  def render_average_overall_quality(venue, opt = {type: 'reviews', supplement: nil})
    rating = venue.round_rating(:overall_quality)
    if venue.overall_quality && venue.overall_quality > 0
      case opt[:type]
      when 'listing'
        rating_all_items = "rating-all-items square-star"
        square_star = "fa fa-square-star"
        display_square_stars(rating, rating_all_items, square_star)
      when 'reviews'
        content_tag :div, class: 'rating-result', itemscope: true, itemtype: "http://data-vocabulary.org/Review-aggregate" do
          rating_all_items = "rating-all-items"
          square_star = "fa fa-square-star-big"
          venue_reviews_size = opt[:supplement].nil? ? venue.reviews.size : venue.neighborhood_reviews.size
          content = display_square_stars(rating, rating_all_items, square_star)
            .concat(
          content_tag(:div, class: 'rating-score'){
            content_tag(:span, venue.overall_quality, itemprop: 'average').concat('/').concat(
              content_tag(:span, 5, itemprop:'best')
            )
          }).concat(content_tag(:span, venue_reviews_size, itemprop: 'count', class: 'hide'))
            opt[:supplement].nil? ? content : content.concat(content_tag :span, opt[:supplement], class: 'supplement')
        end
      end
    end
  end

  def display_square_stars(rating, rating_all_items, square_star)
    content_tag :div, class: "#{rating_all_items}" do
      5.times.map do|t|
        content_tag :i, nil, class: "#{square_star} #{t < rating ? "selected" : nil} #{rating - t == 0.5 ? "half" : nil }"
      end.join.html_safe
    end
  end

  def toggle_comment(comment, len = 450, more = true, opt={})
    return if comment.blank?
    if comment.size <= len + 20
      content_tag :p do
        simple_format comment
      end
    else
      content_tag(:div, class: 'short-remark'){
        content_tag(:p,truncate(strip_tags(simple_format comment), length: len, separator: ' ') +
                    link_to(' more>>', 'javascript:void(0);', class: 'more-or-less',
                            data: {show: '.long-remark', hide: '.short-remark'} ))
      } + content_tag(:div, class: 'long-remark'){
        content_tag(:p){raw(strip_tags(comment)) + link_to(' <<less', 'javascript:void(0);', class: 'more-or-less',
                                                           data: {show: '.short-remark', hide: '.long-remark'} )}
      }
    end
  end

  def building_description(txt, len=700)
    content_tag(:div, class: 'short-remark') {
      content_tag(:p, truncate(strip_tags(simple_format txt), length: len) + link_to('Full Description', 'javascript:void(0);', class: 'more-or-less',
                            data: {show: '.long-remark', hide: '.short-remark'}))
    } + content_tag(:div, class: 'long-remark'){
      content_tag(:p){raw(strip_tags(txt))}}
  end

  def has_lock_review?(index, review_count)
    # !(spider_access? || created_obj?(:reviews) || (index < (review_count * 0.33).round))
    !(spider_access? || created_obj?(:reviews) || (controller_name == 'listings' ? index < 1 : index < (review_count * 0.33).round))
  end

  def no_lock_review_and_neighborhood?(review_count, neigh_review_count)
    if (review_count > 1 && !has_lock_review?(1, review_count)) or review_count <= 1
      if (neigh_review_count > 1 && !has_lock_review?(1, review_count)) or neigh_review_count <= 1
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def render_lock_pop review, index, review_count, opt={}
    if has_lock_review?(index, review_count)
      content_tag :div, class: 'review-lock' do
        content_tag :div, class: 'lock-container' do
          html = content_tag(:i,nil, class: 'fa fa-lock')
          html = html.concat(content_tag :div, 'Our community depends on your contribution', class: 'lock-title key-color') if controller_name != 'listings'
          html = html.concat(
            content_tag(:div, class: 'lock-comment') do
              content_tag(:a,'Contribute your review', href: 'javascript: void(0);', class: 'contribute-review').concat(" to get access to #{(Review.count * 2.1).to_i}+ reviews.")
            end
          )
          unless current_account.present?
            html.concat(
              content_tag(:div, class: 'lock-comment'){
                ((opt[:lock_message2] || "If you have an account with at least one review posted, please ") + content_tag(:a, 'Log In', href: '#sign_in', data: {toggle: 'modal', target: '#sign_in'}, class: 'login')).html_safe
              }
            )
          end
          html
        end
      end
    end
  end

end
