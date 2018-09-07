class AddRefInfoToClientApply < ActiveRecord::Migration
  def change
    add_column :client_applies, :ref_info, :string, default: nil
  end
end
