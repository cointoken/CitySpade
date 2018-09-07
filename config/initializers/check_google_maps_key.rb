#if Rails.env == 'production' && false
  #begin
    #keys = Settings.google_maps.server_keys
    #keys.each do |key|
      #url = "https://maps.googleapis.com/maps/api/geocode/json?address=nyc&sensor=false&key=#{key}"
      #json = RestClient.get url
      #if json.downcase.include?('error')
        #Settings.google_maps.server_keys.delete key
        #title = "Google Maps Key disabled (error)"
        #message = key
        #SystemMailer.notice(title, message)
      #end
    #end
  #rescue => err
    #p err.message
    #p err.backtrace.inspect
  #end
#end
