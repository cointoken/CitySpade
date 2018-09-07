class AddSeedForPoliticalAreasLatlng < ActiveRecord::Migration
  def change
    PoliticalArea.set_latlng
  end
end
