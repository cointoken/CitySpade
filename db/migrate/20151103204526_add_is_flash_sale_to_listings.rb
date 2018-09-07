class AddIsFlashSaleToListings < ActiveRecord::Migration
  def change
    add_column :listings, :is_flash_sale, :boolean, default: false
    add_index :listings, :is_flash_sale
  end
end
