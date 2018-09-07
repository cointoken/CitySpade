require 'net/https'
module Spider
  class Base
    def initialize(opts = {})
      @connections  = {}
      @opts         = opts
      @cookie_store = Spider::CookieStore.new(@opts[:cookies])
      @logger       = Spider::Logger.new
    end

    def is_full_address?(title)
      return false unless title
      title.strip!
      return false if ['bed', 'bath'].any?{|s| title.downcase.include? s}
      if title =~ /^\d+/
        return false if title =~ /^\d+\s?+(st|nd|th)\s/i
        return true
      else
        titles = title.split(',')
        if titles.size > 1
          if titles[1].strip =~ /^\d+/
            return true
          end
        end
      end
      false
    end

    def get_flag_id(flag)
      flag.downcase.starts_with?('rent') ? 1 : 0
    end

    def self.get_flag_id(flag)
      flag.downcase.starts_with?('rent') ? 1 : 0
    end

    def cookie_store
      @cookie_store
    end

    def post_options_to_str_hash(options)
      opts = {}
      options.each do |key, value|
        if value.is_a?(Hash)
          opts[key.to_s] = post_options_to_str_hash(value)
        else
          opts[key.to_s] = value
         # if value.is_a?(Array)
            #opts[key.to_s] = value.join(',')
          #else
            #opts[key.to_s] = value.to_s
          #end
        end
      end
      opts
    end

    def post(url, options = {}, referer = nil)
      options = post_options_to_str_hash(options)
      unless url.is_a?(URI)
        url = URI(url)
        url.path = '/' unless url.path.present?
      end
      loc = url
      limit = 5
      code = nil
      @redirect_to = nil
      begin
        loc = url.merge(loc) if loc.relative?
        response, response_time = post_response(loc, options, referer)
        code = Integer(response.code)
        @redirect_to = redirect?(code) ? URI(response['location']).normalize : (@redirect_to || nil)
        yield response, code, url, response_time if block_given?
        limit -= 1
      end while((loc = redirect_to) && allowed?(redirect_to, url) && limit > 0) && code != 200
      response
    end

    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    def get(url, referer = nil)
      limit = 5
      unless url.is_a?(URI)
        url = URI(url)
        url.path = '/' unless url.path.present?
      end
      loc = url
      code = nil
      @redirect_to = nil
      begin
        # if redirected to a relative url, merge it with the host of the original
        # request url
        loc = url.merge(loc) if loc.relative?
        response, response_time = get_response(loc, referer)
        code = Integer(response.code)
        @redirect_to = redirect?(code) ? URI(response['location']).normalize : (@redirect_to || nil)
        yield response, code, loc, redirect_to, response_time  if block_given?
        limit -= 1
      end while (loc = redirect_to) && allowed?(redirect_to, url) && limit > 0 && code != 200
      response
    end

    def redirect_to
      @redirect_to
    end

    private

    def proxy_host
      @opts[:proxy_host] || @proxy_host
      return nil
    end

    #
    # The proxy port
    #
    def proxy_port
      @opts[:proxy_port] || @proxy_port
      return nil
    end

    def read_timeout
      @opts[:read_timeout]
    end
    def allowed?(to_url, from_url)
      true
      #to_url.host.present? || (to_url.host.nil? || (to_url.host == from_url.host))
    end

    def to_query(options)
      str = []
      options.each do |key, value|
        if value.is_a?(Array)
          str << value.map{ |v|
            "#{key}[]=#{v}"
          }.join('&')
        else
          str << "#{key}=#{value}"
        end
      end
      str.join("&")
    end

    def post_response(url, options={}, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"
      retries = 0
      opts={}
      opts['Cookie'] = @cookie_store.to_s if @cookie_store.present? && accept_cookie?
      begin
        start = Time.now()
        response = connection(url).post(full_path, to_query(options), opts )
        finish = Time.now()
        response_time = ((finish - start) * 1000).round
        @cookie_store.merge!(response['Set-Cookie'])
        return response, response_time
      rescue Timeout::Error, Net::HTTPBadResponse, EOFError => e
        puts e.inspect
        refresh_connection(url)
        retries += 1
        retry unless retries > 3
      end
    end
    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"
      opts = {}
      opts['Cookie'] = @cookie_store.to_s if @cookie_store.present? && accept_cookie?
      opts['User-Agent'] = @opts[:user_agent] if @opts[:user_agent]
      opts['Accept'] = @opts[:accept] if @opts[:accept]
      retries = 0
      begin
        start = Time.now()
        # format request
        req = Net::HTTP::Get.new(full_path, opts)
        # HTTP Basic authentication
        req.basic_auth url.user, url.password if url.user
        response = connection(url).request(req)
        finish = Time.now()
        response_time = ((finish - start) * 1000).round
        @cookie_store.merge!(response['Set-Cookie'])
        return response, response_time
      rescue Timeout::Error, Net::HTTPBadResponse, EOFError => e
        puts e.inspect if defined?(verbose?) && verbose?
        refresh_connection(url)
        retries += 1
        retry unless retries > 3
      end
    end

    def connection(url)
      @connections[url.host] ||= {}

      if conn = @connections[url.host][url.port]
        return conn
      end

      refresh_connection url
    end

    def refresh_connection(url)
      http = Net::HTTP.new(url.host, url.port, proxy_host, proxy_port)

      http.read_timeout = read_timeout if !!read_timeout

      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @connections[url.host][url.port] = http.start
    end
    def redirect?(code)
      (300..307).include?(code)
    end

    def accept_cookie?
      !!@opts[:accept_cookie]
    end

    def domain_name
      'http://cityspade.com'
    end

    def abs_url(url)
      return url if url =~ /^http/
      URI::join(domain_name, URI.escape(url)).to_s
    end
  end

end
