module GooglemapValidate

  def api_check
    get_keys = Settings.google_maps.server_keys
    working = Array.new
    denied = Array.new
    overlimit = Array.new
    others = Array.new
    get_keys.each do |key|
      response = JSON.load(open("https://maps.googleapis.com/maps/api/directions/json?destination=Barclay%20Center,%20Brooklyn,%20NY&key=#{key}&language=en&mode=driving&origin=40.68691,-73.92672"))
      if(response["status"] == "OK")
        working<<key
      elsif(response["status"] == "REQUEST_DENIED")
        denied<<key
      elsif(response["status"] == "OVER_QUERY_LIMIT")
        overlimit << key
      else
        others
      end
    end
    puts "**********Working********"
    puts working
    puts "**********Denied********"
    puts denied
    puts "**********Over Limit********"
    puts overlimit
    puts "**********Othes***********"
    puts others
  
  end


end
