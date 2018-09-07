class OwnerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(owner_id)
    owner = Owner.find(owner_id)
    OwnerMailer.notify(owner).deliver
  end
end
