json.array!(@reviews) do |review|
  json.extract! review, :id, :address, :build_name, :city, :state, :review_type
  json.url review_url(review, format: :json)
end
