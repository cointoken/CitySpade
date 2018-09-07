class AddFormattedAddressToTransportPlace < ActiveRecord::Migration
  def change
    add_column :transport_places, :formatted_address, :string
  end
end
