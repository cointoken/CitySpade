class ListWithUsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(list_with_us_id)
    list_with_us = ListWithUs.find(list_with_us_id)
    ListWithUsMailer.notify(list_with_us).deliver
  end
end
