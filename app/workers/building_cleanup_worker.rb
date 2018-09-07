class BuildingCleanupWorker
  include Sidekiq::Worker

  def perform
    #Building.find_each(&:save)
    #buildings =Building.limit(70000)
    #no_of_buildings = buildings.count
    #no_of_iterations = (no_of_buildings.to_f / 1000).ceil

    #(1..no_of_iterations).each do |i|
    #  buildings.limit(1000).destroy_all
    #end
    #buildings = Building.all
    #buildings.each do |building|
    #  arr = building.formatted_address.split(",")
    #  building.city = arr[1].strip
    #  state = arr[2].strip.split.first
    #  building.state = state
    #  building.save
    #end
    WelcomeMailer.test_mail("Finished saving buildings").deliver
  end
end
