class AddDbSeedBeforeDeployForPhiladelphia < ActiveRecord::Migration
  def change
    if Rails.env == 'production'
      Rails.logger.info "init neighborhood"
      Neighborhood.init_setup
      Rails.logger.info "init transport places"
      TransportPlace.init_data
      Rails.logger.info "init mta info(subway and bus)"
      Rails.logger.info "must get all mta infos"
      # MapsServices::MTAInfo.setup
    end
  end
end
