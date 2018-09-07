class AddColumnsToFsCategories < ActiveRecord::Migration
  def change
    add_column :fs_categories, :plural_name, :string, limit: 100
    add_column :fs_categories, :short_name, :string, limit: 100
    add_column :fs_categories, :icon_prefix, :string
    add_column :fs_categories, :icon_suffix, :string, limit: 20
  end
end
