class AddBaseNumToAddressTranslator < ActiveRecord::Migration
  def change
    add_column :address_translators, :base_num, :string, limit: 6
  end
end
