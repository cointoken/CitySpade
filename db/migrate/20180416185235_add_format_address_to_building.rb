class AddFormatAddressToBuilding < ActiveRecord::Migration
  def change
    add_column :buildings, :formatted_address, :string
    remove_column :buildings, :year_alter1, :integer
    remove_column :buildings, :year_alter2, :integer
    remove_column :buildings, :ct2010, :integer
    remove_column :buildings, :cb2010, :integer
    remove_column :buildings, :allzoning, :string
    remove_column :buildings, :all_zoning1, :string
    remove_column :buildings, :bldg_front, :integer
    remove_column :buildings, :bldg_depth, :integer
    remove_column :buildings, :irr_lot_code, :string
    remove_column :buildings, :tract2010, :integer
    remove_column :buildings, :built_far, :float
    remove_column :buildings, :resid_far, :float
    remove_column :buildings, :comm_far, :float
    remove_column :buildings, :facil_far, :float
    remove_column :buildings, :split_zone, :string
    remove_column :buildings, :bldg_class, :string
    remove_column :buildings, :land_use, :integer
    remove_column :buildings, :easements, :integer
    remove_column :buildings, :sanborn, :string
  end
end
