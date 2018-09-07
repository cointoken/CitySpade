class AddContactNumberToListWithUs < ActiveRecord::Migration
  def change
    add_column :list_with_us, :contact_number, :string
  end
end
