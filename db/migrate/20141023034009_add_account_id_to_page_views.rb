class AddAccountIdToPageViews < ActiveRecord::Migration
  def change
    add_reference :page_views, :account, index: true
  end
end
