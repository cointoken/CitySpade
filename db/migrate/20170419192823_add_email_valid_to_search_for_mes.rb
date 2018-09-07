class AddEmailValidToSearchForMes < ActiveRecord::Migration
  def change
    add_column :search_for_mes, :email_valid, :boolean, default: false
  end
end
