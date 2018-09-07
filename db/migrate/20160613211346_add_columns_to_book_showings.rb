class AddColumnsToBookShowings < ActiveRecord::Migration
  def change
    add_column :book_showings, :name, :string, null: false
    add_column :book_showings, :email, :string, null: false
  end
end
