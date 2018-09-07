class AddCoverToSpadePassImages < ActiveRecord::Migration
  def change
    add_column :spade_pass_images, :cover, :bool, default: false
  end
end
