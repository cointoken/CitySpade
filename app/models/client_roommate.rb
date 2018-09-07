class ClientRoommate < ActiveRecord::Base
  belongs_to :client_checkin
  
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
