class CreateInboxes < ActiveRecord::Migration
  def change
    create_table :inboxes do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
