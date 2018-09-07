class AddSeedForSecondNameToPoliticalArea < ActiveRecord::Migration
  def change
    # PoliticalArea.nyc.sub_areas.where(long_name: 'Ridgewood', target: 'sublocality').update_all(second_name: 'Queens')
    # PoliticalArea.nyc.sub_areas.where(long_name: 'East Elmhurst', target: 'sublocality').update_all(second_name: 'Queens')
  end
end
