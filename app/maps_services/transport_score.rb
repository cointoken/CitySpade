module MapsServices
  class TransportScore
    class << self
      def setup opt = {}
        manhattan opt
        queens opt
        brooklyn opt
        philadelphia opt
        boston opt
        other_city 'chicago', opt
      end

      def fix_score_glt_nine
        manhattan query: 'score_transport > 9.8 or score_transport is null'
        queens query: 'score_transport > 9.8 or score_transport is null'
        brooklyn query: 'score_transport > 9.8 or score_transport is null'
      end
      %w{manhattan queens brooklyn}.each do |pt|
        define_method "#{pt}_area" do
          eval "@#{pt}_area||=PoliticalArea.default_area.sub_areas.where(long_name: pt.capitalize).where('target like ?', 'sublocality%')"
        end
      end

      def other_areas
        return @other_areas if @other_areas
        @other_areas = PoliticalArea.nyc.sub_areas
        %w{manhattan queens brooklyn}.each do |pt|
          area = eval("#{pt}_area")
          next unless area.present?
          @other_areas = @other_areas.where("id not in (#{area.map{|s| s.sub_ids(include_self: true)}.flatten.join(',')})")
        end
        @other_areas
      end

      def manhattan(opt={})
        area_ids = manhattan_area.map{|m| m.sub_ids(include_self: true)}.flatten << other_areas.map{|m| m.id}
        area_ids.flatten!
        listings = []
        if opt.class.to_s == 'Listing'
          listings << opt if area_ids.include? opt.political_area_id
        elsif opt.is_a? Array
          opt.each do |l|
            listings << l if area_ids.include? l.political_area_id
          end
        else
          listings = Listing.cal_transport_distance
          if opt[:query].present?
            listings = listings.where opt[:query]
          end
          listings = listings.where("political_area_id in (#{area_ids.join(',')})")
          .order('listings.flag desc').order('listings.place_flag desc, listings.id desc')
        end
        listings.each do |listing|
          ActiveRecord::Base.transaction do
            transits = listing.transport_distances.where(mode: 'transit')
            walkings = listing.transport_distances.where(mode: 'walking')
            if transits.size != 6 || walkings.size != 6
              listing.cancel_cal_transport_distances
              next
            end
            transits.each do |transit|
              transit.cal_duration += 120
            end
            hash = []
            walkings.each_with_index do |walking,index|
              if walking.duration > 1200
                hash << transits[index]
                next
              end
              v = walking.duration <= 600 ? 1.5 : 1.2
              walking.cal_duration = walking.duration / v
              hash << walking
            end
            schools = []
            schools << hash.delete_at(-2)
            schools << hash.delete_at(-1)
            schools = sort_transport(schools)
            before_three_ave = hash[0..2].sum{|a| a.duration} / 3
            if before_three_ave <= 22 * 60
              hash.delete_at 3
            elsif before_three_ave <= 30 * 60
              hash[3].cal_duration = hash[3].duration * 1.2
            end
            # when a school time within 10 min delete other a
            if schools.first.mode == 'walking'
              if schools.first.duration <= 600
                schools.first.cal_duration = schools.first.duration / 1.5
                cal_detail(hash, from: :cal_duration, cal_sym: '-', cal_val: 120 )
              elsif schools.first.duration <= 1200
                schools.first.cal_duration = schools.first.duration / 1.2
                cal_detail(hash, from: :cal_duration, cal_sym: '-', cal_val: 60 )
              end
            end
            schools.delete_at 1
            hash[0..2] = sort_transport(hash[0..2])
            if hash.first.mode == 'walking'
              if hash.first.duration <= 600
                cal_detail(hash, from: :cal_duration, cal_sym: '-', cal_val: 120,if: ->(h) { h != hash.first } )
              elsif hash.first.duration <= 1200
                cal_detail(hash, from: :cal_duration, cal_sym: '-', cal_val: 60,if: ->(h) { h != hash.first } )
              end
            end
            sum = hash.sum{|s| s.cal_duration}
            sum += schools.sum{|s| s.cal_duration}
            aveage = sum / (hash.size + schools.size)
            aveage = aveage / 60.0

            score_transport = math_func(aveage)
            listing.update_column :score_transport, score_transport
          end
        end
      end
      # cal detail ,type: 0 => all , 1 => expect school, 2 => only school
      def cal_detail(hash, opt = {})
        opt = {from: :duration, to: :cal_duration, cal_sym: '+', cal_val: 1}.merge! opt
        hash.each do |h|
          if opt[:if_for_all]
            next unless opt[:if_for_all].call(hash)
          end
          if opt[:if]
            next unless opt[:if].call(h)
          end
          h.send("#{opt[:to]}=", h.send(opt[:from]).send(opt[:cal_sym], opt[:cal_val]))
        end
      end

      def sort_transport(schools)
        arr = []
        size = schools.size
        schools.each do |school|
          if school.mode == 'walking'
            arr << schools.delete(school)
          end
        end
        if arr.size == size
          return arr.sort{|x,y| x.duration <=> y.duration}
        end
        arr << schools
        arr.flatten
      end

      def math_func(x, area = 'manhattan')
        if x <= 10
          return 10
        else
          case area
          when 'brooklyn'
            p1 = 4.812
            p2 = -77.88
            p3 = 2864
            p4 = 213.1
            p5 = 21.61
            p6 = 2.139
            q1 = -21.91
            q2 = 459.1
            q3 = -790.8
            q4 = -182
            q5 = -19.56
          when 'queens'
            p1 = 1.781
            p2 = 250.1
            p3 = 0.05492
            p4 = -0.2249
            p5 = 0.5
            p6 = 0.9628
            q1 = 4.927
            q2 = 133.4
            q3 = 8.559
            q4 = 0.9198
            q5 = 0.234
          else
            p1 =       6.454
            p2 =      -327.7
            p3 =        4940
            p4 =       865.1
            p5 =        60.9
            p6 =      -2.391
            q1 =      -51.23
            q2 =       830.3
            q3 =       -1819
            q4 =       138.5
            q5 =       107.7
          end
          num = p1*x**5 + p2*x**4 + p3*x**3 + p4*x**2 + p5*x + p6
          den = x**5 + q1*x**4 + q2*x**3 + q3*x**2 + q4*x + q5
          score = (num / den)
          if area == 'manhattan'
            if score < 7.0
              score = (7 - 4.5) * (([score - 6.45, rand * 0.01].max / (7 - 6.45)) ** 0.54) + 4.5
            end
          end
          score = 9.8 + rand * 0.15 if score > 9.8
          score.round(2)
        end
      end
      def brooklyn(opt={})
        area_ids = brooklyn_area.map{|m| m.sub_areas(include_self: true).map{|m| m.id}} # << other_areas.map{|m| m.id}
        area_ids.flatten!
        listings = []
        if opt.class.to_s == 'Listing'
          listings << opt if area_ids.include? opt
        elsif opt.is_a? Array
          opt.each do |l|
            listings << l if area_ids.include? l.political_area_id
          end
        else
          listings = Listing.cal_transport_distance
          if opt[:query].present?
            listings = listings.where opt[:query]
          end
          listings = listings.where("political_area_id in (#{area_ids.join(',')})")
          .order('listings.flag desc').order('listings.place_flag desc, listings.id desc')
        end
        listings.each do |listing|
          ActiveRecord::Base.transaction do
            transits = listing.transport_distances.where(mode: 'transit')
            walkings = listing.transport_distances.where(mode: 'walking')
            if transits.size != 6 || walkings.size != 6
              listing.cancel_cal_transport_distances
              next
            end
            transits.each do |transit|
              transit.cal_duration += 120
            end
            hash = []
            walkings.each_with_index do |walking,index|
              if walking.duration > 1200
                hash << transits[index]
                next
              end
              v = walking.duration <= 600 ? 1.5 : 1.2
              walking.cal_duration = walking.duration / v
              hash << walking
            end
            schools = []
            schools << hash.delete_at(-2)
            schools << hash.delete_at(-1)
            schools = sort_transport(schools)
            walks = []
            (hash + schools).each do |h|
              walks << h if !['Grand Central', 'SoHo'].include?(h.name) && h.mode == 'walking' && h.duration <= 1200
            end
            if walks.size == 2
              hash.delete_if{ |h| h.name == 'Grand Central'}
            elsif walks.size > 2
              hash.delete_if{ |h| ['Grand Central', 'SoHo'].include?(h.name) }
            end
            sum = hash.sum{|s| s.cal_duration}
            sum += schools.sum{|s| s.cal_duration}
            aveage = sum / (hash.size + schools.size)
            aveage = aveage / 60.0
            p aveage
            score_transport = math_func(aveage, 'brooklyn')
            listing.update_column :score_transport, score_transport
          end
        end
      end
      def queens(opt={})
        area_ids = queens_area.map{|m| m.sub_areas(include_self: true).map{|m| m.id}} # << other_areas.map{|m| m.id}
        area_ids.flatten!
        if opt.class.to_s == 'Listing'
          if area_ids.include? opt.political_area_id
            listings = [opt]
          else
            listings = []
          end
        elsif opt.is_a? Array
          listings = []
          opt.each do |l|
            listings << l if area_ids.include? l.political_area_id
          end
        else
          listings = Listing.cal_transport_distance
          if opt[:query].present?
            listings = listings.where opt[:query]
          end
          listings = listings.where("political_area_id in (#{area_ids.join(',')})")
          .order('listings.flag desc').order('listings.place_flag desc, listings.id desc')
        end
        listings.each do |listing|
          ActiveRecord::Base.transaction do
            transits = listing.transport_distances.where(mode: 'transit')
            walkings = listing.transport_distances.where(mode: 'walking')
            if transits.size != 6 || walkings.size != 6
              listing.cancel_cal_transport_distances
              next
            end
            transits.each do |transit|
              transit.cal_duration += 120
            end
            hash = []
            walkings.each_with_index do |walking,index|
              if walking.duration > 60 * 25
                hash << transits[index]
                next
              end
              v = walking.duration <= 60 * 15 ? 1.5 : 1.2
              walking.cal_duration = walking.duration / v
              hash << walking
            end
            schools = []
            schools << hash.delete_at(-2)
            schools << hash.delete_at(-1)
            schools = sort_transport(schools)
            tmp_du = hash.sum{|h| ['SoHo', 'Grand Central'].include?(h.name) ? h.duration : 0}
            hash.each do |h|
              if ['SoHo', 'Grand Central'].include?(h.name) && h.mode == 'transit'
                if tmp_du <= 2 * 30 * 60 || h.duration <= 30 * 60
                  h.duration = h.duration / 1.2
                end
              end
            end
            low_40 = 0
            high_60 = 0
            schools.each do |s|
              if s.duration <= 60 * 40
                low_40 += 1
              elsif s.duration >  60 * 40
                high_60 += 1
              end
            end
            hash.each do |h|
              h.duration = h.duration - low_40 * 2 + high_60 * 2
            end
            sum = hash.sum{|s| s.cal_duration}
            aveage = sum / hash.size
            aveage = aveage / 60.0
            score_transport = math_func(aveage, 'queens')
            listing.update_column :score_transport, score_transport
          end
        end
      end

      def philadelphia(opt={})
        listings = []
        if opt.class.to_s == 'Listing'
          listings << opt if PoliticalArea.philadelphia.sub_ids(include_self: true).include? opt.political_area_id
        elsif opt.is_a? Array
          opt.each do |l|
            listings << l if PoliticalArea.philadelphia.sub_ids(include_self: true).include? l.political_area_id
          end
        else
          listings = Listing.enables.cal_transport_distance.where(political_area_id: PoliticalArea.philadelphia.sub_ids).where(opt[:query]).limit(opt[:limit])
        end
        transport_aveage_time = [1320, 1220, 1506, 1380]
        listings.each do |listing|
          transits = listing.transport_distances.where(mode: 'transit').limit(4)
          walkings = listing.transport_distances.where(mode: 'walking').limit(4)
          origin_score = 0
          if transits.size != 4 or walkings.size != 4
            listing.cancel_cal_transport_distances
            next
          end
          transport_aveage_time.each_with_index do |time, index|
            walking = walkings[index]
            if walking.duration < time
              origin_score += (walking.duration / time.to_f) ** 3.5
            else
              transit = transits[index]
              if transit.duration < time
                origin_score += (transit.duration / time.to_f) ** 2
              else
                origin_score += (transit.duration / time.to_f) ** 0.5
              end
            end
          end
          score = math_func_except_nyc(origin_score, 'philadelphia')
          score_transport = score
          listing.update_column :score_transport, score_transport
        end
      end

      def boston(opt={})
        area_ids = PoliticalArea.boston.sub_areas(include_self: true).map{|m| m.id}
        area_ids.flatten!
        listings = []
        if opt.class.to_s == 'Listing'
          listings << opt if area_ids.include? opt.political_area_id
        elsif opt.is_a? Array
          opt.each do |l|
            listings << l if area_ids.include? l.political_area_id
          end
        else
          listings = Listing.enables.cal_transport_distance.where(political_area_id: PoliticalArea.boston.sub_ids(include_self: true)).where(opt[:query]).limit(opt[:limit])
        end
        transport_aveage_time = [1200, 1450, 800, 1260]
        listings.each do |listing|
          transits = listing.transport_distances.where(mode: 'transit').limit(4)
          walkings = listing.transport_distances.where(mode: 'walking').limit(4)
          origin_score = 0
          if transits.size != 4 or walkings.size != 4
            listing.cancel_cal_transport_distances
            next
          end
          transport_aveage_time.each_with_index do |time, index|
            walking = walkings[index]
            if walking.duration < time
              origin_score += (walking.duration / time.to_f) ** 3.5
            else
              transit = transits[index]
              if transit.duration < time
                origin_score += (transit.duration / time.to_f) ** 2
              else
                origin_score += (transit.duration / time.to_f) ** 0.5
              end
            end
          end
          score = math_func_except_nyc(origin_score, 'boston')
          score_transport = score
          listing.update_column :score_transport, score_transport
        end
      end

      def other_city(city_name, opt={}, transport_aveage_time = [1200, 1450, 800, 1260])
        area_ids = PoliticalArea.send(city_name.downcase).sub_areas(include_self: true).map{|m| m.id}
        area_ids.flatten!
        listings = []
        if opt.class.to_s == 'Listing'
          listings << opt if area_ids.include? opt.political_area_id
        elsif opt.is_a? Array
          opt.each do |l|
            listings << l if area_ids.include? l.political_area_id
          end
        else
          listings = Listing.enables.cal_transport_distance.where(political_area_id: PoliticalArea.send(city_name.downcase).sub_ids(include_self: true)).where(opt[:query]).limit(opt[:limit])
        end
        #transport_aveage_time = [1200, 1450, 800, 1260]
        listings.each do |listing|
          transits = listing.transport_distances.where(mode: 'transit').limit(4)
          walkings = listing.transport_distances.where(mode: 'walking').limit(4)
          origin_score = 0
          if transits.size != 4 or walkings.size != 4
            listing.cancel_cal_transport_distances
            next
          end
          transport_aveage_time.each_with_index do |time, index|
            walking = walkings[index]
            if walking.duration < time
              origin_score += (walking.duration / time.to_f) ** 3.5
            else
              transit = transits[index]
              if transit.duration < time
                origin_score += (transit.duration / time.to_f) ** 2
              else
                origin_score += (transit.duration / time.to_f) ** 0.5
              end
            end
          end
          score = math_func_except_nyc(origin_score, city_name)
          score_transport = score
          listing.update_column :score_transport, score_transport
        end
      end



      def math_func_except_nyc(origin_score, area = nil)
        case area
        when 'philadelphia', 'boston', 'chicago'
          l =  4 / origin_score
          if l > 1
            score = 8.0 * (l ** 0.12)
            if score > 9.95
              score = 9.95
            end
            score
          else
            score = 8.0 * (l ** 0.35)
            if score < 6.4
              score = 6.4
            end
            score
          end
          score.round(2)
        else
          nil
        end
      end
    end
  end
end
