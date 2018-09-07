class PageView < ActiveRecord::Base
  belongs_to :page, polymorphic: true
  scope :all_num, -> { sum(:num) }
  def all_num
    PageView.where(page_type: self.page_type, page_id: self.page_id).sum(:num)
  end

  def account
    Account.find(self.account_id) if self.account_id.present?
  end

  def page
    Listing.find(self.page_id) if self.page_id.present? and self.page_type == "ContactAgent"
  end
end
