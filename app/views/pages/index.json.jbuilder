json.array!(@pages) do |page|
  json.extract! page, :id, :name, :permalink, :content
  json.url page_url(page, format: :json)
end
