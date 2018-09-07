require 'matrix'
module MapsServices
  class PriceScore
    class << self
      def config(redo_flag = false)
        @config_score_arg = nil if redo_flag
        @config_score_arg ||= begin
                                h = YAML::load_file File.join(Rails.root,'config', 'price_score_config.yml')
                                hash = {}
                                h.each do |key, value|
                                  keys = key.split('(--')
                                  k = keys.first.strip
                                  areas = PoliticalArea.default_area.sub_areas.where('short_name = ? or long_name=?', k, k)
                                  key_ids = areas.map{|area| area.sub_areas(include_self: true).map{|a| a.id}}.flatten.uniq
                                  if keys.size == 2
                                    k = keys.last.gsub(/\)/, '').strip
                                    areas = PoliticalArea.default_area.sub_areas.where('short_name = ? or long_name = ?', k, k)
                                    key_ids  = key_ids - areas.map{|area| area.sub_areas(include_self: true).map{|a| a.id}}.flatten.uniq
                                  end
                                  hash[key_ids] = value.is_a?(String) ? (h[value] || value) : value
                                  hash[key_ids]['neighborhood'] = key if hash[key_ids].is_a?(Hash)
                                end
                                hash.each do |key1, value|
                                  if value.is_a?(String)
                                    if areas = PoliticalArea.default_area.sub_areas.where('short_name = ? or long_name=?', value, value)
                                      key_ids = areas.map{|area| area.sub_areas(include_self: true).map{|a| a.id}}.flatten.uniq
                                      hash[key1] = hash[key_ids]
                                      hash[key1]['neighborhood'] = "#{key1}*#{value}" if hash[key1].is_a?(Hash)
                                    end
                                  end
                                end
                                hash.delete_if do |_, val|
                                  if val.is_a?(Hash)
                                    unless val['score'] && val['score'].size > 4
                                      true
                                    end
                                  else
                                    true
                                  end
                                end
                                hash
                              end
      end

      def get_score_arg_from_neighborhood(area)
        config.each do |key, value|
          return value if key.include? area.id
        end
        return nil
      end

      def undata_ids
        @undata_ids ||= PoliticalArea.where("id not in (#{config.keys.flatten.uniq.join(",")})").map{|l| l.id}
      end

      def get_score_arg(area, listing = nil)
        get_score_arg_from_neighborhood(area) || begin
        # 根据 area与在config文件中距离最近的area
        if area && area.lat.present?
          tmp = PoliticalArea.nyc.sub_areas.where(id: config.keys.flatten).order("(lat - #{area.lat}) * (lat - #{area.lat}) + (lng - #{area.lng}) * (lng - #{area.lng})").first
        end
        config[[area.id]] = get_score_arg_from_neighborhood(tmp)
        config[[area.id]]
        end
      end

      def setup(*args)
        auto_save = true
        if args.size > 0
          if args.first.class.to_s == 'Listing'
            return if args.first.flag == 0
            auto_save = false
            listings = [args.first]
          elsif  args.first.is_a?(Array)
            listings = [args.first]
          end
          if args.last.is_a?(Hash) && opt = args.last
            listings = Listing.unscoped.latlngs.rentals.where('beds >= 0 and price > 0').where(opt[:query])
            listings = listings.where(political_area_id: PoliticalArea.nyc.sub_ids)
          end
        else
          listings = Listing.unscoped.latlngs.rentals.where('beds >= 0 and price > 0')
          listings = listings.where(political_area_id: PoliticalArea.nyc.sub_ids)
        end
        listings.each do |listing|
          next unless listing.political_area
          next unless listing.is_rental? && listing.price > 0
          next unless PoliticalArea.nyc
          next unless PoliticalArea.all_city_sub_area_ids.include? listing.political_area.id
          if !PoliticalArea.nyc.sub_ids.include?(listing.political_area_id) || listing.state_name != 'NY'
            setup_score_except_nyc(listing, auto_save)
          else
            score_arg = get_score_arg(listing.political_area, listing) #config[listing.political_area] || config[listing.political_area]
            if score_arg
              index = bed_index_in_score_arg(listing, score_arg)
              if index && index > -1
                arg = []
                if index == 0
                  arg << [[score_arg["#{listing.beds}br"].first / 5, listing.price].min, 10]
                  arg << [score_arg["#{listing.beds}br"].first,score_arg['score'].first]
                  arg << [score_arg["#{listing.beds}br"][1],score_arg['score'][1]]
                elsif index == score_arg['score'].size - 1
                  arg << [score_arg["#{listing.beds}br"][-2], score_arg['score'][-2]]
                  arg << [score_arg["#{listing.beds}br"].last,score_arg['score'].last]
                  arg << [[listing.price, score_arg["#{listing.beds}br"].last * 5].max, 6.4]
                else
                  arg << [score_arg["#{listing.beds}br"][index - 1], score_arg['score'][index - 1]]
                  arg << [score_arg["#{listing.beds}br"][index], score_arg['score'][index ]]
                  arg << [score_arg["#{listing.beds}br"][index + 1], score_arg['score'][index + 1]]
                end
                score_price = cal_score(arg, listing).round(2)
                if score_price < 6.4
                  score_price = 6.4
                elsif score_price > 9.8
                  score_price = 9.80 + (rand / 6).round(2)
                  if listing.price <= 300
                    score_price = nil
                  end
                end
                if auto_save && !listing.new_record?
                  listing.update_column :score_price, score_price
                  # listing.save
                else
                  listing.score_price = score_price
                end
              end
            else
              setup_score_except_nyc(listing, true)
            end
          end
        end
      end

      # 根据 矩阵构造 函数求解，求price score
      # score = x * price ** 2 + y + price + z
      def cal_score(arg, listing)
        x, y, z = get_arg(*arg)
        x * listing.price ** 2 + y * listing.price + z
      end

      # 取listing 相近 price score 的价格参数 [score, price][score, price][score, price]
      def bed_index_in_score_arg(listing, score_arg)
        bed_prices = score_arg["#{listing.beds}br"]
        if bed_prices
          if bed_prices.size < 2
            return -1
          end
          if bed_prices.first >= listing.price
            return 0
          end
          if bed_prices.last <= listing.price
            return bed_prices.size - 1
          end
          bed_prices.each_index do |index|
            if bed_prices[index] <= listing.price
              if index < bed_prices.size - 1
                if listing.price < bed_prices[index + 1]
                  return  2 * listing.price - bed_prices[index + 1] - bed_prices[index] > 0 ? index + 1 : index
                end
              end
            end
          end
        end
      end

      def get_arg(x, y, z)
        matrix_d = []
        [x.first, y.first, z.first].each do |v|
          matrix_d << [v ** 2, v ,1]
        end
        matrix_d = Matrix[*matrix_d]
        matrix_x = Matrix[[x.last, x.first, 1], [y.last, y.first, 1], [z.last, z.first, 1]]
        matrix_y = Matrix[[x.first**2, x.last, 1], [y.first**2, y.last, 1], [z.first**2, z.last, 1]]
        matrix_z = Matrix[[x.first**2, x.first, x.last], [y.first**2, y.first, y.last], [z.first**2, z.first, z.last]]
        [matrix_x.determinant, matrix_y.determinant, matrix_z.determinant].map{|d| d/matrix_d.determinant.to_f}
      end
      def setup_score_except_nyc(listing, auto_save)
        return unless check_cal_valid_except_nyc(listing)
        #return if PoliticalArea.nyc.sub_ids.include? listing.political_area_id
        score_arg = get_score_arg_except_nyc(listing)
        score_index = get_index_for_score_arg_except_nyc(listing, score_arg)
        arr = []
        if score_arg.size == 1
          arr << [listing.price * 5, 5.0]
          arr << score_arg[score_index]
          arr << [listing.price / 10, 9.99]
        elsif score_index == 0
          arr << [score_arg[score_index].first * 5,  5.0]
          arr << score_arg[score_index]
          arr << score_arg[score_index + 1]
        elsif score_index == score_arg.size - 1
          arr << score_arg[score_index - 1]
          arr << score_arg[score_index]
          arr << [score_arg[score_index].first / 10, 9.99]
        else
          arr << score_arg[score_index - 1]
          arr << score_arg[score_index ]
          arr << score_arg[score_index + 1]
        end
        score_price = cal_score(arr, listing).round(2)
        if score_price < 6.4
          score_price = 6.4
        elsif score_price > 9.9 #&& score_price < 10
          score_price = 9.6 + (rand / 3).round(2)
        elsif !(score_price > 0)
          score_price = nil
        end
        if auto_save && !listing.new_record?
          listing.update_column :score_price, score_price
        else
          listing.score_price = score_price
        end
      end

      def get_index_for_score_arg_except_nyc(listing, score_arg)
        index = 0
        score_arg.each_with_index do |score,i|
          if score.first < listing.price
            if i > 0
              (score.first - listing.price).abs > (score_arg[i - 1].first - listing.price).abs ? (index = i - 1) : (index = i)
            end
            return index
          end
        end
        if score_arg.last.first >=  listing.price
          return score_arg.size - 1
        end
        index
      end


      def get_score_arg_except_nyc(listing)
        @config_score_arg_except_nyc = {}
        if @config_score_arg_except_nyc[listing.political_area_id] && @config_score_arg_except_nyc[listing.political_area_id]["#{listing.beds}br"]
          return @config_score_arg_except_nyc[listing.political_area_id]["#{listing.beds}br"]
        else
          return to_score_arg_except_nyc(listing)
        end
      end

      # 取其他的相关的 listings 作为计算参数
      def get_config_score_arg_except_nyc_for_political_area(listing)
        area       = listing.political_area
        ## 同名 listing
        same_areas   = listing.city.sub_areas(include_self: true).where(long_name: area.long_name).to_a
        # 是否总Listings数量小于16
        begin
          ## 只取 neighborhood 的 political area
          same_areas = same_areas.select{|s| s.target == 'neighborhood' }
          listings = Listing.rentals.where(display_beds: listing.beds).where(political_area_id: same_areas.map{|s| s.sub_ids(include_self: true)}.flatten).where('status = 0 or created_at > ?', Time.now - 2.month)
          ## 取 上级 political_area
          same_areas = same_areas.map{|s| s.parent}.compact
        end while(listings.count < 16 && same_areas.any?{|s| s.target == 'neighborhood'}) 
        ## 如果数量不够，直接取这个city 全部 的listing
        if listings.count < 16
          listings = listing.city.all_listings.rentals.where(display_beds: listing.beds).where('status = 0 or created_at > ?', Time.now - 2.month)
        end
        [area, listings]
      end

      def to_score_arg_except_nyc(listing)
        # @config_score_arg_except_nyc[area.id]["#{listing.beds}br"] ||= []
        area, listings = get_config_score_arg_except_nyc_for_political_area(listing)
        listings = listings.order(:price)
        arg = []
        min_score = 6.5
        max_score = 9.8
        price = listings.average(:price).to_f.round(2)
        phases = get_average_price_phase(listings)
        if phases.size == 1
          price = listings.average(:price).to_f.round(2)
          arg.insert(1, [price, (6.5 + 9.8)/2])
        else
          phases_prices = []
          phases.each do |phase|
            next unless phase.last > phase.first
            phases_prices << listings[phase.first...phase.last].sum(&:price) / (phase.last - phase.first) #.offset(phase.first).limit(phase.last - phase.first).average(:price).to_f.round(2)
          end
          phases_prices.sort!{|x, y| y <=> x}
          phase_score = (max_score - min_score) / (phases_prices.size + 1)
          phases_prices.each_with_index do |price, index|
            arg << [price, min_score + (index + 1) * phase_score]
          end
          arg.insert(0,[listings.last.price, min_score]) if arg[0][0] != listings.last.price
          arg << [listings.first.price, max_score] if arg[-1][0] != listings.first.price
        end
        arg.delete_if{|s| s.blank?}
        arg.uniq!{|s| s.first}
        arg = decorator_price_config(arg, beds: listing.beds, count: listings.size)
        ## 修改由于参数差距太大引起的不正常分数
        if arg.size > 2
          for i in (2...arg.size)
            tmp = (arg[i - 1].first - arg[i - 2].first).abs / (arg[i - 1].first - arg[i].first).abs.to_f
            if tmp > 5
              arg[i - 1] = [arg[i - 2].first - (arg[i - 2].first - arg[i].first) / 3, arg[i - 1].last]
            elsif 1 / tmp > 5
              arg[i - 1] = [arg[i - 2].first - (arg[i - 2].first - arg[i].first) * 2 / 3, arg[i - 1].last]
            end
          end
        end
        arg_first = [arg.first.first * 3, 6.2]
        arg_last  = [arg.last.first / 3, 9.95]
        arg.delete_at 0 if arg.size > 1
        arg.insert(0, arg_first)
        arg.delete_at -1 if arg.size > 2
        arg << arg_last
        @config_score_arg_except_nyc[area.id] ||= {}
        @config_score_arg_except_nyc[area.id]["#{listing.beds}br"] = arg
        arg
      end

      def decorator_price_config(arg, opts = {beds: 0, count: 0})
        return arg if opts[:count] > 30
        arg
      end

      def get_average_price_phase(listings)
        size = listings.count
        phase_all = 1
        phase_num =  size
        while phase_num / 2 != 0 && phase_all < 4
          phase_num = phase_num / 2
          phase_all += 1
        end
        phase_power_num = 2 ** (phase_all - 1)
        phase_indexs = []
        mod_num = size % phase_power_num
        mod_num_except = 0
        last_num = 0
        phase_power_num.times do |i|
          num = (phase_num * (i + 1) + mod_num_except)
          p "*" * 100
          p mod_num
          p phase_all
          p "*" * 100
          if mod_num > 0  && (i / ((phase_all.to_f / mod_num)) >= 1) && mod_num_except < mod_num
            num += 1
            mod_num_except += 1
          end
          phase_indexs << [last_num, num]
          last_num = num
        end
        phase_indexs[-1][-1] = phase_indexs[-1][-1] + (mod_num - mod_num_except)
        new_phase_indexs = []
        case phase_indexs.size
        when 8
          new_phase_indexs = [phase_indexs[0],[phase_indexs[0].first, phase_indexs[1].last],phase_indexs[1],
                              [phase_indexs[0].first, phase_indexs[3].last],phase_indexs[2],[phase_indexs[2].first, phase_indexs[3].last],phase_indexs[3],
                              [phase_indexs[0].first, phase_indexs.last.last], phase_indexs[4], [phase_indexs[4].first, phase_indexs[5].last], phase_indexs[5],
                              [phase_indexs[4].first, phase_indexs[7].last],phase_indexs[6], [phase_indexs[6].first, phase_indexs[7].last], phase_indexs[7]]
        when 4
          new_phase_indexs =  [phase_indexs[0],[phase_indexs[0].first, phase_indexs[1].last],phase_indexs[1],
                               [phase_indexs[0].first, phase_indexs[3].last],phase_indexs[2],[phase_indexs[2].first, phase_indexs[3].last],phase_indexs[3]]
        when 2
          new_phase_indexs =  [phase_indexs[0],[phase_indexs[0].first, phase_indexs[1].last],phase_indexs[1]]
        else
          new_phase_indexs = phase_indexs
        end
        new_phase_indexs
      end
      def check_cal_valid_except_nyc(listing = nil)
        true
      end
    end
  end
end
