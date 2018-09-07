if ['production', 'background'].include? Rails.env
  # production service Intranet ip
  $redis = Redis.new host: '172.31.47.95'
else
  $redis = Redis.new
end
