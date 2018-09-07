class AddRoleToAccount < ActiveRecord::Migration
  def up
    add_column :accounts, :role, :string
  end

  def down
    remove_column :accounts, :role
  end
end
