class ContactsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(contact_id)
    contact = Contact.find(contact_id)
    ContactMailer.notify(contact).deliver
  end
end
