class CreateBuildings < ActiveRecord::Migration
  def change
    create_table :buildings do |t|
      t.string :city, limit: 20
      t.string :borough, limit: 20
      t.integer :block
      t.integer :lot
      t.integer :cd
      t.integer :ct2010
      t.integer :cb2010
      t.integer :school_dist
      t.integer :councli
      t.string :zipcode, limit: 5
      t.string :fire_comp, limit: 20
      t.integer :police_prct
      t.string :address
      t.string :zone_dist1, limit: 20
      t.string :overlay1, limit: 20
      t.string :s_p_dist1, limit: 20
      t.string :all_zoning1, limit: 20
      t.string :allzoning, limit: 20
      t.string :split_zone, limit: 20
      t.string :bldg_class, limit: 20
      t.integer :land_use
      t.integer :easements
      t.string :owner_type, limit: 5
      t.string :owner_name
      t.integer :lot_area
      t.integer :bldg_area
      t.integer :com_area
      t.integer :res_area
      t.integer :office_area
      t.integer :retail_area
      t.integer :garage_area
      t.integer :strge_area
      t.integer :factry_area
      t.integer :other_area
      t.integer :area_source
      t.integer :num_bldgs
      t.integer :num_floors
      t.integer :units_res
      t.integer :units_total
      t.integer :lot_front
      t.integer :lot_depth
      t.integer :bldg_front
      t.integer :bldg_depth
      t.string :ext, limit: 5
      t.integer :prox_code
      t.string :irr_lot_code, limit: 5
      t.integer :lot_type, limit: 2
      t.integer :bsmt_code, limit: 2
      t.integer :year_built
      t.integer :built_code
      t.integer :year_alter1
      t.integer :year_alter2
      t.string :hist_dist, limit: 50
      t.string :land_mark
      t.float :built_far
      t.float :resid_far
      t.float :comm_far
      t.float :facil_far
      t.float :boro_code
      t.string :bbl, limit: 20
      t.integer :tract2010
      t.integer :condo_no
      t.string :sanborn, limit: 20
      t.string :version, limit: 20

      t.timestamps
    end
      add_index :buildings, [:city, :borough, :address]
  end
end
