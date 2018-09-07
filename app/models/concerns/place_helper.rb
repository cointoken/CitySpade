module PlaceHelper
  def ll
    @ll ||= Geokit::LatLng.new self.lat, self.lng
  end

  def get_mta_st(local = 'nyc')
    query_names = self.name.sub(/Station$/, '').strip.split('/')
    sts = self.listing.political_area.all_sts.where(target: self.target)
    opts = {}
    if query_names.size == 1
      opts[:name] = query_names.first
      if opts[:name] =~ /^(W|E)\s/
        name_1 = opts[:name].sub(/^W/, 'West')
        name_1 = name_1.sub(/^E/, 'East')
        opts[:name_1] = name_1
      elsif opts[:name] =~ /^(West|East)\s/
        name_1 = opts[:name].sub(/^West/, 'W')
        name_1 = name_1.sub(/^East/, 'E')
        opts[:name_1] = name_1
      end
      opts.each do |key, value|
        opts[key] = "#{value}%"
      end
      if opts[:name_1]
        sts = sts.where("name like :name or name like :name_1",opts)
      else
        sts = sts.where("name like :name",opts)
      end
    else
      name_sql = '1'
      long_sql = '1'
      query_names.each_with_index do |q,index|
        q.sub(/Street/i, 'St')
        q.sub(/(Avenue)|(Aven)|(Ave)/i, 'AV')
        name_sql += " and name like :name_#{index}"
        long_sql += " and long_name like :name_#{index}"
        opts["name_#{index}".to_sym] = "%#{q}%"
      end
      name_sql_1 = '1'
      long_sql_1 = '1'
      other_sql_flag = false
      query_names.each_with_index do |q,index|
        if q =~ /^(W|E)\s/
          q.sub!(/^W/, 'West')
          q.sub!(/^E/, 'East')
        elsif
          q.sub!(/^West/, 'W')
          q.sub!(/^East/, 'E')
        else
          next
        end
        name_sql_1 += " and name like :name_1_#{index}"
        long_sql_1 += " and long_name like :name_1_#{index}"
        opts["name_1_#{index}".to_sym] = "%#{q}%"
        other_sql_flag = true unless other_sql_flag
      end
      if other_sql_flag
        sts = sts.where("((long_name is null and #{name_sql}) or (#{long_sql})) or ((long_name is null and #{name_sql_1}) or (#{long_sql_1}))", opts)
      else
        sts = sts.where("(long_name is null and #{name_sql}) or (#{long_sql})", opts)
      end
    end
    sts.uniq{|st| st.mta_info_line_id}
    get_real_sts(sts)
  end
  MIN_PLACE_ST_DIS = 0.7
  def real_st?(st)
    return true if st.lat.blank? || st.lng.blank?
    place_ll = Geokit::LatLng.new self.lat, self.lng
    st_ll    = Geokit::LatLng.new st.lat, st.lng
    dis = place_ll.distance_to st_ll
    dis < MIN_PLACE_ST_DIS
  end

  def get_real_sts(sts)
    sts.select{|st| real_st?(st)}
  end

  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def self.cal_distances
      where('listing_places.distance is null or listing_places.distance > 0').order('id desc').each do |place|
        MapsServices::DistanceMatrix.setup nil, place
      end
    end
  end
end
