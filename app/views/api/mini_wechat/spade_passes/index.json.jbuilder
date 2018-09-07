json.array!(@spade_passes) do |spade_pass|
  json.set! :id, spade_pass.id
  json.set! :title, spade_pass.title
  json.set! :city, spade_pass.city
  json.set! :borough, spade_pass.borough
  json.set! :special_offers, spade_pass.special_offers
  json.set! :contact_tel, spade_pass.contact_tel
  json.set! :street_address, spade_pass.street_address
  json.set! :spade_pass_type, spade_pass.spade_pass_type
  json.set! :discounts_expired_formatted_date, spade_pass.discounts_expired_formatted_date
  json.set! :images,
    if spade_pass.spade_pass_images.present?
      spade_pass.cover_image.image_url(:thumb)
    else
      ""
    end
  json.set! :special_offers_array, spade_pass.special_offers_array
  end
