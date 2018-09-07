class AddLockableToDevise < ActiveRecord::Migration
  def change
    add_column :accounts, :failed_attempts, :integer, default: 0, null: false # Only if lock strategy is :failed_attempts
    add_column :accounts, :unlock_token, :string # Only if unlock strategy is :email or :both
    add_column :accounts, :locked_at, :datetime
    add_index :accounts, :unlock_token, unique: true
  end
end
