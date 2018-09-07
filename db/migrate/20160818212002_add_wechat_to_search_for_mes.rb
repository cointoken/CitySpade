class AddWechatToSearchForMes < ActiveRecord::Migration
  def change
    add_column :search_for_mes, :wechat, :string
  end
end
