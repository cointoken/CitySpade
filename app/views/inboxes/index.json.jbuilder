json.array!(@inboxes) do |inbox|
  json.extract! inbox, :id, :title, :content
  json.url inbox_url(inbox, format: :json)
end
