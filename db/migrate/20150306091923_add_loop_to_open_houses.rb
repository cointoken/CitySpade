class AddLoopToOpenHouses < ActiveRecord::Migration
  def change
    add_column :open_houses, :loop, :boolean, default: false
    ## 下次循环间隔天数
    add_column :open_houses, :next_days, :integer, limit: 2
    add_column :open_houses, :expired_date, :date
  end
end
