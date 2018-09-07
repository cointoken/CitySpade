module ListingSearch

  def custom_search(current_area = PoliticalArea.default_area, opts = {})
    is_no_fee = !opts[:noFee].blank? if opts[:flag] =~ /^rent/i
    opts = decorator_params(current_area, opts)
    listings = Listing.where(flag: opts[:flag]).enables
    ## check if use or query
    query_or_flag = opts[:neighborhood_ids].present?
    querry_arrs = []
    if opts[:neighborhood_ids].present?
      sql = "listings.political_area_id in (#{opts[:neighborhood_ids].join(',')})"
    else
      sql = "listings.political_area_id in (#{current_area.sub_ids.join(',')})"
    end
    if query_or_flag
      if opts[:zipcode].present?
        sql << " or listings.zipcode='#{opts[:zipcode]}'"
      end
      #listings = listings.where(sql)
      if opts[:political_area_id].present?
        sql << " or political_area_id in (#{opts[:political_area_id].join(',')})"
        if opts[:area] && opts[:area].size > 6
          if opts[:area] =~ /^\d+\s/
            sql << " or title like ? "
            querry_arrs << "#{opts[:area]}%"
          else
            sql << " or formatted_address like ?"
            querry_arrs << "%#{opts[:area]}%"
          end
        end
      end
      if opts[:title].present?
        if opts[:title] =~ /^\d+(\-\d+)?\s/
          sql << " or listings.formatted_address rlike ?"
          querry_arrs << "^#{opts[:title]}"
        else
          sql << " or listings.formatted_address rlike ?"
          querry_arrs <<  "#{opts[:title]}"
        end
      end
      #querry_arrs.insert_at 0, sql
      listings = listings.where(sql, *querry_arrs)
    else
      listings = listings.where sql
      if opts[:zipcode].present?
        listings = listings.where(zipcode: opts[:zipcode])
      end
      if opts[:political_area_id].present?
        area_sql = "political_area_id in (#{opts[:political_area_id].join(',')})"
        if opts[:area] && opts[:area].size > 6
          if opts[:area] =~ /^\d+\s/
            area_sql = ["#{area_sql} or title like ?", "#{opts[:area]}%"]
          else
            area_sql = ["#{area_sql} or formatted_address like ?", "%#{opts[:area]}%"]
          end
        end
        listings = listings.where(area_sql)
      end
      if opts[:title].present?
        if opts[:title] =~ /^\d+(\-\d+)?\s/
          listings = listings.where("listings.formatted_address rlike  ?", "^#{opts[:title]}")
        else
          listings = listings.where("listings.formatted_address rlike  ?", "#{opts[:title]}")
        end
      end
    end
    #if opts[:zipcode].present?
    #if opts[:neighborhood_ids].present?
    #listings = listings.where('1 or zipcode=?', opts[:zipcode])
    #else
    #listings = listings.where(zipcode: opts[:zipcode])
    #end
    #end
    listings = listings.where(no_fee: true) if is_no_fee
    #if opts[:political_area_id].present?
    #area_sql = "political_area_id in (#{opts[:political_area_id].join(',')})"
    #if opts[:area] && opts[:area].size > 6
    #if opts[:area] =~ /^\d+\s/
    #area_sql = ["#{area_sql} or title like ?", "#{opts[:area]}%"]
    #else
    #area_sql = ["#{area_sql} or formatted_address like ?", "%#{opts[:area]}%"]
    #end
    #end
    #listings = listings.where(area_sql)
    #end
    listings = listings.where("listings.price >= ?",opts[:price_from]) if opts[:price_from].present?
    listings = listings.where("listings.price <= ?",opts[:price_to]) if opts[:price_to].present?
    if opts[:beds].present?
      #clear empty item in arry
      opts[:beds].reject!(&:empty?)
      max_bed = opts[:beds].last
      if max_bed.to_i > 3
        listings = listings.where("listings.display_beds >= ? OR listings.display_beds IN (?)", max_bed, opts[:beds])
      else
        listings = listings.where(display_beds: opts[:beds]) if opts[:beds].present?
      end
    end

    if opts[:baths].present?
      #clear empty item in arry
      opts[:baths].reject!(&:empty?)
      max_bath = opts[:baths].last
      if max_bath.to_f > 1.5
        listings = listings.where("listings.baths >= ? OR listings.baths IN (?)", max_bath, opts[:baths])
      else
        listings = listings.where(baths: opts[:baths]) if opts[:baths].present?
      end
    end

    if opts[:args]
      listings = listings.where(opts[:args])
    end

    # first page display 2~4 listings

    listings = listings.order('listings.place_flag desc')
    # order by image
    listings = listings.order('listings.is_full_address desc')
    listings = listings.order('listings.listing_image_id is null')
    ## order by current location
    if opts[:lat] && opts[:lng]
      listings = listings.order("power(listings.lat - #{opts[:lat]}, 2) + power(listings.lng - #{opts[:lng]}, 2)")
      listings = listings.within(1, units: :kms, origin: [opts[:lat], opts[:lng]])
    end
    listings = listings.order(opts[:custom_order]) if opts[:custom_order]
    if opts[:order]
      listings = listings.order(opts[:order])
      if opts[:order] == 'price'
        listings = listings.order('listings.beds').order('(listings.price / listings.beds) desc')
      end
    end
    # second search , delete is_full_address condition
    no_fees = listings.where(no_fee: true, is_full_address: true).order(id: :desc).limit(4)
    if no_fees.present?
      listings = listings.order("id in (#{no_fees.map(&:id).join(',')}) desc")
    end
    #if size
    #opts[:args].delete :is_full_address
    #end
    # custom  no fees order
    listings = listings.order("to_days(listings.created_at) desc")
    if no_fees.present? and listings.where(no_fee: false).present?
      max_listing_id = listings.where(no_fee: false).order(id: :desc).first.id
      no_fee_id = no_fees.first.id
      tmp_id = 0
      if no_fee_id > max_listing_id
        tmp_id = (no_fee_id - max_listing_id)
      end
      listings = listings.order("listings.id % ( 24 - listings.no_fee * 8)")
      # listings = listings.order("(listings.id - #{tmp_id} * (listings.id > #{max_listing_id}) * listings.no_fee  + (listings.no_fee * (listings.id % 32) / 32) * (#{max_listing_id} - listings.id)) desc")
    end
    #end custom no fees order
    listings
  end

  private
  def decorator_params(current_area, opts)
    search_params = {}
    if opts[:neighborhood]
      if opts[:neighborhood] == "midtown-west"
        neighborhood = current_area.sub_areas.where(permalink: "hells-kitchen")
      else
        neighborhood = current_area.sub_areas.where(permalink: opts[:neighborhood])
      end
      unless neighborhood.present?
        neighborhood = current_area.sub_areas.where('long_name like :q', q: "#{opts[:neighborhood]}%")
      end
      if neighborhood.present?
        search_params[:political_area_id] = []
        neighborhood.each do |neigh|
          search_params[:political_area_id] << neigh.sub_areas(include_self: true, include_nearby: false).map{|n| n.id.to_i}
        end
      end
      search_params[:political_area_id] ||= [0]
    end
    if opts[:neighborhoods].present?
      neighs = opts[:neighborhoods].reject{|s| s.blank?}
      if neighs.present?
        objs = current_area.sub_areas.where('long_name in (:n) or second_name in (:n)', n: neighs)
        search_params[:neighborhood_ids] = objs.map{|s| s.sub_ids(include_self: true)}.flatten.uniq
      end
    end
    decorator_title(opts[:title] || opts[:address], current_area, search_params) if opts[:title].present? || opts[:address].present?
    search_params[:beds] = opts[:beds] = [*opts[:beds]].delete_if{|b| b.blank?}.flatten.sort if opts[:beds].present?
    search_params[:baths] = opts[:baths] = [*opts[:baths]].delete_if{|b| b.blank?}.flatten.sort if opts[:baths].present?
    search_params[:price_from] = opts[:price_from].gsub(/\D/, '') if opts[:price_from]
    search_params[:price_to]   = opts[:price_to].gsub(/\D/, '') if opts[:price_to]
    if opts[:flag].to_s =~ /^\d$/
      search_params[:flag] = opts[:flag]
    else
      search_params[:flag] = opts[:flag] ? (opts[:flag].starts_with?('sale') ? 0 : 1) : 1
    end
    search_params[:custom_order] = opts[:custom_order] if opts[:custom_order].present?
    if opts[:sort]
      search_params[:order] = sort_keys[opts[:sort]]
    end
    if opts[:lat] && opts[:lng]
      search_params[:lat] = opts[:lat].to_f
      search_params[:lng] = opts[:lng].to_f
    end
    search_params
  end
  def decorator_title(title, current_area, search_params, is_address_flag = false)
    titles = title.split(',')
    titles.delete_at(-1) if titles.present? && titles.last.strip =~ /^(United States|US)$/i
    if titles.present? && current_area.long_name == 'New York' && titles.first.try(:downcase) == 'new york'
      search_params[:political_area_id] = current_area.children.where(long_name: 'Manhattan').map{|s| s.sub_ids(include_self: true)}.flatten
    end
    if titles.present? && titles.last.strip.size == 2
      state = PoliticalArea.states.where(short_name: titles.last.strip).first
      if state
        if state.short_name == 'NY'
          current_area = PoliticalArea.nyc
        else
          current_area = state
        end
        titles.delete_at(-1)
      end
    end
    titles.each do |t|
      t.strip!
      if t =~ /^\d{5}$/
        # zipcode = ZipcodeArea.where(zipcode: t)
        # if zipcode.present?
        search_params[:zipcode] ||= []
        search_params[:zipcode] << t
        # else
        #  search_params[:title] ||= []
        #  search_params[:title] << t
        # end
      elsif t =~ /^\w/
        neighborhoods = current_area.sub_areas(include_self: true).where("short_name = :t or long_name = :t or second_name = :t", t: t)#current_areas_by_neighborhoods(t)
        if neighborhoods.blank?
          neighborhoods = current_area.sub_areas.where('long_name like :t', t: "#{t}%")
        end
        ## dont search neighborhood when the title is search for address
        if neighborhoods.present? && !is_address_flag
          search_params[:political_area_id] ||= []
          if neighborhoods.first.is_neighborhood?
            search_params[:political_area_id] << neighborhoods.map{|s| s.sub_ids(include_self: true, include_nearby: false)}.flatten
          else
            if search_params[:political_area_id].blank?
              search_params[:political_area_id] << neighborhoods.map{|s| s.sub_ids(include_self: true, include_nearby: false)}.flatten
            else
              search_params[:political_area_id] = search_params[:political_area_id] & neighborhoods.map{|s| s.sub_ids(include_self: true, include_nearby: false)}.flatten
            end
          end
          search_params[:political_area_id].flatten!
          search_params[:political_area_id].uniq!
          search_params[:area] ||= []
          ## 都进行 like 匹配
          search_params[:area] << t  # if search_params[:political_area_id].blank? || is_match_title
        else
          search_params[:title] ||= []
          search_params[:title] << t
        end
      else
        search_params[:title] ||= []
        search_params[:title] << t
      end
    end
    search_params[:area] = to_formatted_title(search_params[:area].join(' ')) if search_params[:area]
    if search_params[:title]
      search_params[:title] = to_formatted_title(search_params[:title].join(', '))
      #search_params[:title].gsub!(/\se\s/i, ' E(ast)? ')
      #search_params[:title].gsub!(/\sw\s/i, ' W(est)? ')
      #search_params[:title].gsub!(/\sn\s/i, ' N(orth)? ')
      #search_params[:title].gsub!(/\ss\s/i, ' S(outh)? ')
    end
    search_params
  end
  def sort_keys
    {'price.desc' => 'listings.price desc', 'price.asc' => 'listings.price asc', 'price' => 'listings.score_price desc', 'transport' => 'score_transport desc'}
  end

  def to_formatted_title(title)
    if title
      title.gsub!(/(^N|\sN)(orth)?\s/i, ' N(orth)? ')
      title.gsub!(/(^S|\sS)(outh)?\s/i, ' S(outh)? ')
      title.gsub!(/(^E|\sE)(ast)?\s/i, ' E(ast)? ')
      title.gsub!(/(^W|\sW)(est)?\s/i, ' W(est)? ')
      title.gsub!(/(^St|\sSt)(reet)?\s/i, ' St(reet)? ')
      title.gsub!(/(^Ave|\sAve)(nue)?\s/i, ' Ave(nue)? ')
      title.gsub! 'Street', 'St(reet)?'
      title.gsub! 'Avenue', 'Ave(nue)?'
      title.gsub! 'street', 'St(reet)?'
      title.gsub! 'avenue', 'Ave(nue)?'
      title.gsub! 'East', 'E(ast)?'
      title.gsub! 'West', 'W(est)?'
      title.gsub! 'North', 'N(orth)?'
      title.gsub! 'South', 'S(outh)?'
      title
    end
  end
end
