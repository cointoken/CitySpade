class ChangeIntegerTypeToDisqus < ActiveRecord::Migration
  def change
    change_column :disqus, :thread_id, :integer, limit: 8
    change_column :disqus, :post_id, :integer, limit: 8, default: 0
    add_index :disqus, :thread_id
  end
end
