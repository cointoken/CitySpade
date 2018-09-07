module Api::ApplicationHelper
  def to_rabl_array_or_hash(object = nil, attrs = [])
    if object.class == Array
      object.map{|o| to_rabl_array_or_hash(o)}
    else
      if attrs.present?
        hash = {}
        attrs.each do |attr|
          hash[attr] = object.send attr
        end
        hash
      else
        object.attributes
      end
    end
  end

  def display_score_for_api(listing, target = :score_price)
    if listing[target.to_s].present?
      "#{sprintf("%.2f",listing[target.to_s])}/10"
    elsif target == :score_price && listing['price'] > 10000 && listing['flag'] == Settings.flags.rental
      'Luxury'
    else
      "---"
    end
  end

  def transt_type_icon_url(mode=nil)
    img = mode == 'walking' ? "icons/walk.png" : "icons/public.png"
    asset_url img
  end
end
