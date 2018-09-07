class BrokerUpdateWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(broker_id, info, listing_id)
    broker = Broker.find broker_id
    listing = Listing.find listing_id
    listing.update_column :broker_id, broker_id
    if info.size == 2
      agent = broker.agents.find_and_update_from_hash({name: info.last})
      listing.update_column :agent_id, agent.id
    end
  end
end
