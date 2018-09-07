namespace :set do
  desc "Set state for each Transport place"
  task trans_place: :environment do
    TransportPlace.first(37).each do |place|
      arr = place.formatted_address.split(",")
      if arr.count == 5
        place.state = arr[3].split().first.strip
      elsif arr.count == 4
        place.state = arr[2].split().first.strip
      else
        place.state = arr.last.strip
      end
      place.save
    end
    TransportPlace.where(state: "New York").each do |place|
      place.state = "NY"
      place.save
    end
  end
end
