class AddStateToTransportPlace < ActiveRecord::Migration
  def change
    add_column :transport_places, :state, :string
  end
end
