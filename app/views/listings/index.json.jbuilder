json.array!(@listings) do |listing|
  json.extract! listing, :id, :title, :political_area_id, :unit, :beds, :baths, :sq_ft, :type_name, :contact_name, :contact_tel
  json.url listing_url(listing, format: :json)
end
