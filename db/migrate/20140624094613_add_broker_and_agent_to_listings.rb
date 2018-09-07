class AddBrokerAndAgentToListings < ActiveRecord::Migration
  def change
    add_reference :listings, :broker, index: true
    add_reference :listings, :agent, index: true
  end
end
