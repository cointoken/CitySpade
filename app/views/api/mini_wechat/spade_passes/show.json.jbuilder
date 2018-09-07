json.extract! @spade_pass, :id,
                         :title,
                         :political_area_id,
                         :zipcode,
                         :street_address,
                         :city,
                         :borough,
                         :description,
                         :spade_pass_type,
                         :special_offers,
                         :discounts_expired_formatted_date,
                         :contact_tel,
                         :created_at,
                         :updated_at,
                         :lat,
                         :lng
json.set! :images,
  if @spade_pass.spade_pass_images.present?
    @spade_pass.spade_pass_images.map(&:image_url)
  else
    []
  end
json.set! :special_offers_array, @spade_pass.special_offers_array
json.set! :like, (@like.blank? or @like == 0) ? 0 : 1
