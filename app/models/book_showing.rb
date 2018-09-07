class BookShowing < ActiveRecord::Base
  belongs_to :show_date, class_name: 'ShowingDate', foreign_key: :date_id
  belongs_to :time_slot, class_name: 'ShowingTimeSlot', foreign_key: :slot_id
  validates :name, :email, presence: true
  validate :datetime_present

  def datetime_present
    if !date_id.present? && !slot_id.present?
      errors[:base] << "Please select a date and time"
    end
  end
end
