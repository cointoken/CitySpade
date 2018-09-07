module RecordStorage
  class << self
    def spider(opt={}, val = nil)
      opt = {method: :get, flag: :error}.merge opt
      key = "spider:sites:#{opt[:flag].downcase}:#{opt[:target].downcase}"
      opt[:method].to_sym == :get ? $redis.get(key):
        $redis.set(key, val || opt[:val])
    end
  end
end
