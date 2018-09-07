class AddSeedToFsCategories < ActiveRecord::Migration
  def change
    FsCategory.upgrade
  end
end
