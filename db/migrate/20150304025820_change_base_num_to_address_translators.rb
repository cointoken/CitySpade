class ChangeBaseNumToAddressTranslators < ActiveRecord::Migration
  def change
    change_column :address_translators , :base_num, :string, limit: 15
  end
end
