class Disqus < ActiveRecord::Base
  belongs_to :disqus_obj, polymorphic: true
  FORUM = 'production-cityspade'

  def comments
    if thread_id
      Disqus.posts_list thread: self.thread_id
    else
      []
    end
  end
  def new_comments
    Disqus.new_posts_list thread: self.thread_id 
  end
  class << self
    def new_posts_list opt = {}
      json = posts_list opt 
      result = []
      tmp_max_post_id = max_post_id
      json.response.each do |res|
        result << res if res['id'].to_i > tmp_max_post_id
      end
      result
    end

    def threads_list
      DisqusApi.v3.threads.list(forum: FORUM)
    end

    def posts_list opt={}
      DisqusApi.v3.posts.list({forum: FORUM}.merge opt)
    end

    def threads_details(thread_id)
      DisqusApi.v3.threads.details(forum: FORUM, thread: thread_id)['response']
    end

    def max_post_id
      dis = Disqus.order(post_id: :desc).first
      if dis
        dis.post_id
      else
        0
      end
    end

    def update
      new_posts_list.each do |res|
        thread_id = res['thread']
        obj = Disqus.find_by_thread_id thread_id
        unless obj
          thread = Disqus.threads_details(thread_id)
          link = thread['link']
          obj_id, obj_type = link.split('/').reverse
          obj_id = obj_id.split('-').first
          obj_type = obj_type.classify
          obj = Disqus.create(disqus_obj_type: obj_type, disqus_obj_id: obj_id, thread_id: thread_id, post_id: res['id'].to_i)
        end
        obj.post_id = res['id'] if obj.post_id < res['id'].to_i
        obj.save
      end
    end
  end
end
