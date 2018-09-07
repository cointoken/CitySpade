module  ListingSpider
  def spider_class
    @spider_class ||= begin
                        if self.broker_site_name
                          Spider::Sites::Base.descendants.select{|s| s.to_s.underscore.include? self.broker_site_name.underscore}.first
                        end
                      end
  end
  def spider
    @spider ||= spider_class.new
  end

  def nokogiri_object
    @nokogiri_object ||= begin
                           if self.url
                             res = spider.get self.url
                             @spider_redirect_to = spider.send(:redirect_to)
                             if res.code == '200'
                               Nokogiri::HTML res.body.to_utf8
                             end
                           end
                         end
  end
  def spider_redirect_to
    @spider_redirect_to ||= begin
                              spider.get self.url
                              spider.send(:redirect_to)
                            end
  end

  def check_url_ok_by_redirect?
    redirect_to = spider_redirect_to
    if redirect_to
      redirect_to.path == URI(self.url).path
    end
    return true
  end

  def spider_title
    @spider_title ||= begin
                        if spider.respond_to?('get_title')
                          spider.get_title(nokogiri_object)
                        end
                      end
  end
  def update_title_from_spider
    if spider_title.present?
      if spider_title =~ /^\d/ && spider_title =~ /\d\s/
        return if self.title == spider_title
        self.title = spider_title
        self.is_full_address = true
        self.save
        #self.street_address = nil
        #self.formatted_address = nil
          #self.update_columns self.slice(:title, :is_full_address, :street_address)
      end
    end
  end
end
