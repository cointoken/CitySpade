module Facebook
  module GraphReview
    FACEBOOK_BASE_GRAPH_URL = "https://graph.facebook.com/me/cityspade:review?"
    def to_facebook_graph_url(opts= {})
      opts[:method] ||= 'POST'
      URI.escape(FACEBOOK_BASE_GRAPH_URL + hash_query(opts))
      #URI.escape(FACEBOOK_BASE_GRAPH_URL + opts.to_param)
    end
    
    def hash_query(opts={})
     query = "" 
     opts.each do |key, value|
       query << "&" if query.present?
       query << "#{key}=#{value}"
     end
     query
    end
    def spider
      @spider = Spider::Base.new
    end
    private :hash_query, :spider


    def post_building_review(token, url)
      spider.get to_facebook_graph_url(access_token: token, building: url)
    end
    def post_neighborhood_review(token, url)
      spider.get to_facebook_graph_url(access_token: token, neighborhood: url)
    end
  end
end
