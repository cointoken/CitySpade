class ClientApply < ActiveRecord::Base
  attr_accessor :curr_street, :curr_city, :curr_state, :curr_country, :curr_zip
  serialize :status, Array
  has_many :documents, dependent: :destroy, class_name: 'Document', foreign_key: 'client_id'
  accepts_nested_attributes_for :documents, reject_if: :all_blank
  before_create :set_access_token
  belongs_to :account
  #scope :documents

  def dob=(s)
    if s.include? "/"
      write_attribute(:dob, Date.strptime(s, "%m/%d/%Y"))
    elsif s.include? "-"
      write_attribute(:dob, Date.strptime(s, "%Y-%m-%d"))
    end
  end

  def start_date=(s)
    if s.include? "/"
      write_attribute(:start_date, Date.strptime(s, "%m/%d/%Y"))
    elsif s.include? "-"
      write_attribute(:start_date, Date.strptime(s, "%Y-%m-%d"))
    end
  end

  def has_pets?
    value = true
    if self.pet.nil?
      value = false
    end
    return value
  end

  def guarantor_status
    arr = []
    self.status.each do |x|
      case x
      when "1"
        arr << "Annual income at least 40X the monthly rent"
      when "2"
        arr << "A guarantor with annual income at least 80X the monthly rent (NY, NJ, CT)"
      when "3"
        arr << "A guarantor with annual income at least 80X the monthly rent (all other states)"
      when "4"
        arr << "A guarantor with annual income at least 80X the monthly rent (outside U.S.)"
      when "5"
        arr << "No guarantor candidates"
      when "6"
        arr << "Willing to pay full year's rent upfront"
      when "7"
        arr << "Willing to pay partial rent upfront / extra security deposit"
      when "8"
        arr << "Willing to pay extra month to third party company for lease guarantee"
      end
    end
    return arr
  end

  def to_param
    "#{id}-#{SecureRandom.hex(7)}"
  end

  def deposit=(s)
    write_attribute(:deposit, self.deposit + s.to_f)
  end


  private

  def set_access_token
    self.access_token = generate_token
  end

  def generate_token
    loop do
      token = SecureRandom.hex(3)
      break token unless ClientApply.where(access_token: token).exists?
    end
  end

  def self.to_csv(options = {})
    #column_names = ["ID", "Name", "Building", "Unit", "Email", "Phone", "Hear about us", "Create Time", "Deposit"]
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |client|
        #csv << [client.id, "#{client.first_name} #{client.last_name}", client.building, client.unit, client.email, client.phone, (client.referral || "") + (client.ref_info.nil? ? "" : ": #{client.ref_info}"), client.created_at.in_time_zone('America/New_York').strftime("%m/%d/%Y %H:%M"), client.deposit, client.agency]
        csv << client.attributes.values_at(*column_names)
      end
    end
  end

end
