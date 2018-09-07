json.array!(@admin_reviews) do |admin_review|
  json.extract! admin_review, :id, :address, :building_name, :cross_street, :city, :state, :status
  json.url admin_review_url(admin_review, format: :json)
end
