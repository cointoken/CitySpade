class AddModeToTransportDistances < ActiveRecord::Migration
  def change
    add_column :transport_distances, :mode, :string, limit: 20
  end
end
