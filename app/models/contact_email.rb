class ContactEmail < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true

  EMAIL_REGEX = /\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  validates_format_of :email, with: EMAIL_REGEX 

  def self.search(to_mail)
    where('LOWER(email) LIKE :to_mail', to_mail: "%#{to_mail.downcase}%")
  end
end
