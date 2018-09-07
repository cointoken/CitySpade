class CreateDisqus < ActiveRecord::Migration
  def change
    create_table :disqus do |t|
      t.string :disqus_obj_type
      t.integer :disqus_obj_id
      t.integer :thread_id
      t.integer :post_id

      t.timestamps
    end
    add_index :disqus, :disqus_obj_id
  end
end
