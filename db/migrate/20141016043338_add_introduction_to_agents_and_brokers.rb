class AddIntroductionToAgentsAndBrokers < ActiveRecord::Migration
  def change
    add_column :agents, :introduction, :text
    add_column :brokers, :introduction, :text
  end
end
