class MailNotifyWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(account_id, flag_type = nil, opts = {})
    account = Account.find account_id if account_id
    case flag_type.to_sym
    when :welcome
      WelcomeMailer.notify(account).deliver
    when :recommend
      RecommendMailer.notify(account, :recommend_listings_by_access).deliver
    when :send_message_to_agent
      ContactMailer.send_message_to_agent(opts).deliver
    when :verify_office_account
      ContactMailer.verify_office_account(account).deliver
    when :send_flash_email
      ContactMailer.send_flash_email(opts).deliver
    end
  end
end
