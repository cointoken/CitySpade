class AddInitNycData < ActiveRecord::Migration
  def change
    say 'init NYC Buildings data'
   # unless Rails.env.development?
      #Building.try(:init_ny_building_from_sql)
      #say 'init finished'
    #else
      #say 'development environment, please execute Building.init_ny_building_from_sql by self'
    #end
  end
end
