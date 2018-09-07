class RemoveReferenceAndAttribute < ActiveRecord::Migration
  def change
    remove_column :client_checkins, :add_type, :boolean
    remove_reference :book_showings, :client, index: true, foreign_key: true
  end
end
