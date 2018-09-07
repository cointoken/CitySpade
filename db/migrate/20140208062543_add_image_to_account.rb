class AddImageToAccount < ActiveRecord::Migration
  def up
    add_column :accounts, :image, :string
  end

  def down
    remove_column :accounts, :image
  end
end
