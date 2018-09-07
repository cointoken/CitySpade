class AccountInbox < ActiveRecord::Base
  belongs_to :account
  belongs_to :inbox
  validates_presence_of :account_id, :inbox_id

  validates_uniqueness_of :account_id, scope: :inbox_id

  default_scope {order('is_read,created_at DESC')}
  scope :unread, -> { where(is_read: false) }

  def read_inbox
  	self.is_read = true
  	self.save
  end
end
