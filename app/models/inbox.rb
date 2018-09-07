class Inbox < ActiveRecord::Base
  attr_accessor :account_id
	has_many :account_inboxes	, dependent: :destroy
	validates_presence_of :title, :content

	after_create :send_inbox

  default_scope {order('created_at DESC')}

  def send_inbox
    if account_id.blank?
      accounts = Account.all
    else
      accounts = [Account.find(account_id)]
    end
    accounts.each do |user|
      AccountInbox.create!(account_id: user.id, inbox_id:self.id)
    end
  end

  def user_read_number
    self.account_inboxes.where(is_read: true).count
  end

  def user_receive_number
    self.account_inboxes.count
  end

  def reader_percentage
    "#{self.reader_number}/#{self.receiver_number}"
  end
end
