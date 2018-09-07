class AddCalDurationTransportDistances < ActiveRecord::Migration
  def change
    add_column :transport_distances, :cal_duration, :integer
  end
end
