class AddIsTopToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :is_top, :boolean
  end
end
