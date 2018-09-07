class Reputation < ActiveRecord::Base
  Categories = ["collect", "room", "building"]

  belongs_to :reputable, polymorphic: true
  belongs_to :account

  validates_presence_of :account_id, :reputable_type, :reputable_id, :category
  validates_inclusion_of :category, in: Categories
  validates_uniqueness_of :category, scope: [:account_id, :reputable_type, :reputable_id]
  before_create :update_collect_num_for_like
  after_destroy :update_collect_num_for_unlike
  private
  def  update_collect_num_for_like
    if self.reputable.respond_to? :collect_num
      self.reputable.collect_num ||= 0
      self.reputable.collect_num += 1
      self.reputable.update_column :collect_num, self.reputable.collect_num
    end
  end
  def update_collect_num_for_unlike
    if self.reputable.respond_to? :collect_num
      self.reputable.collect_num ||= 0
      self.reputable.collect_num -= 1
      self.reputable.collect_num = 0 if self.reputable.collect_num < 0
      self.reputable.update_column :collect_num, self.reputable.collect_num
    end
  end
end
