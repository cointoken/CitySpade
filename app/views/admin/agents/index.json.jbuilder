json.array!(@admin_brokers) do |admin_broker|
  json.extract! admin_broker, :id, :name, :tel, :email
  json.url admin_broker_url(admin_broker, format: :json)
end
