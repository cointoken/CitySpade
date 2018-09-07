class AddReferralToSearchForMe < ActiveRecord::Migration
  def change
    add_column :search_for_mes, :referral, :string
  end
end
