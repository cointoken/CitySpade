class AddPageViewIdIndexToPageViews < ActiveRecord::Migration
  def change
    add_index :page_views, :page_id
  end
end
