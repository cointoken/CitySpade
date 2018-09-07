class ClientCheckin < ActiveRecord::Base
  has_many :client_roommates, dependent: :destroy, foreign_key: 'client_id'
  has_many :checkin_buildings, dependent: :destroy, foreign_key: 'client_id'
  accepts_nested_attributes_for :client_roommates, reject_if: :all_blank
  accepts_nested_attributes_for :checkin_buildings, reject_if: :all_blank

  validates :first_name, :last_name, :email, :phone, presence: true
  validates :email, uniqueness: true
  validates :phone, length: {is: 14, message: "number is invalid"}


  def first_name=(s)
    write_attribute(:first_name, s.to_s.titleize)
  end
  
  def last_name=(s)
    write_attribute(:last_name, s.to_s.titleize)
  end

  def full_name
    full_name = "#{first_name} #{last_name}"
  end
end
