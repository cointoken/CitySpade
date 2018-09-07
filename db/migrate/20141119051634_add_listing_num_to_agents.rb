class AddListingNumToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :listing_num, :integer
  end
end
