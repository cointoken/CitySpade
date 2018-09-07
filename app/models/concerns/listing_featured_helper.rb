module ListingFeaturedHelper
  
  def featured_for(how_many)
    if self.featured == false
      self.update_attributes(featured: true, featured_at: Time.now, featured_until: Time.now + how_many.days)
    end
  end

  def un_feature
    if self.featured
      self.update_attributes(featured: false, featured_at: nil, featured_until: nil)
    end
  end

  def check_featured_time
    if self.featured && (self.feature_until < Time.now)
      self.un_feature
    end
  end
end
