class APICount
  class << self
    def keys
      if $redis
        @@keys ||= $redis.keys.select{|s| s.start_with?('api.count')}.uniq{|s| s.split(':').last}.map{|s| s.split(':').last}
      end
    end

    def get(target, day = nil)
      $redis.get(get_key(target, day))
    end

    def update target
      set target
    end

    private
    def set(target)
      if $redis
        key = get_key target
        num = $redis.get(key).to_i + 1
        $redis.set(key, num)
      end
    end
    def get_key target, day = nil
      "api.count:#{day || Time.now.strftime('%Y-%m-%d')}:#{target}"
    end
  end
end
