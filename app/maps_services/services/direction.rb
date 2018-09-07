module MapsServices
  class Direction < Base
    def base_url
      'https://maps.googleapis.com/maps/api/directions/json'
    end
    def rows
      if json['status'] != 'OK'
        return {}
      end
      json['routes'].first['legs'].first
    end
    def duration
      rows['duration']
      #rows.map{|m| m['duration']}
    end
    def distance
      rows['distance']
      #rows.map{|m| m['distance']}
    end

    def status
      json['status']
    end

    def get(flag = true)
      @get ||= begin 
                 if @@limits[self.class.to_s] == 'false'
                   '{}'
                 else
                   limit = 5
                   begin 
                     limit -= 1
                     res = spider.get get_url
                   end while res.code != '200' && limit > 0
                   json = MultiJson.load(res.body)
                   if ['OK', 'ZERO_RESULTS'].include? json['status']
                     res.body
                   else
                     if flag && json['status'] == 'OVER_QUERY_LIMIT'
                       @logger.info json
                       @logger.info 'redo get url'
                       @logger.info get_url
                       Settings.google_maps.server_keys.delete_if{|s| s == @options[:key]}
                       if Settings.google_maps.server_keys.blank?
                         @@limits[self.class.to_s] = 'false'
                         @logger.info get_url
                         '{}'
                       else
                         #@options[:key] = Settings.google_maps.server_keys.sample
                         sleep(10)
                         @get = nil
                         get true
                       end
                     else
                       # @@limits[self.class.to_s] = 'false'
                       @logger.info get_url
                       '{}'
                     end
                   end
                 end
               end
      @logger.info @get
      @get
    end
  end
end
