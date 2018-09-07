class SearchForMe < ActiveRecord::Base
  serialize :boroughs, Array
  serialize :transportation, Array
  validates :name, :beds, :baths, :budget, :move_in_date, :email, presence: true
  validates :is_employed, inclusion: { in: [true, false]}
  before_save :normalize_wechat
  #before_save :email_verifier
  def normalize_wechat
    self.wechat.present? || self.wechat = nil
  end

  def self.normalize_all_wechat
    SearchForMe.all.each do |sfm|
      sfm.save
    end
  end

  def self.to_csv(options = {})
    column_names = ["ID", "Name", "Boroughs", "Beds", "Baths", "Budget", "Move-In", "Employed", "Transportation", "Email", "Wechat", "Email Valid", "Create Time"]
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |product|
        csv << [product.id, product.name, product.boroughs, product.beds, product.baths, product.budget, product.move_in_date, product.is_employed? ? "Yes" : "No", product.transportation, product.email, product.wechat, product.email_valid? ? "Yes" : "No", product.created_at.in_time_zone('America/New_York').strftime("%m/%d/%Y %H:%M")]
      end
    end
  end

  #def email_verifier
  #  if EmailVerifier.check(self.email) == true
  #  else
  #    self.email = nil
  #  end
  #end
end
