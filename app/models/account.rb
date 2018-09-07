class Account < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :lockable, 
    :omniauthable, :omniauth_providers => [:facebook]

  mount_uploader :image, AvatarUploader

  has_many :account_omniauths
  has_many :blogs
  has_many :reputations
  has_many :search_records

  has_many :account_inboxes
  has_many :inboxes, through: :account_inboxes

  has_many :reviews, dependent: :destroy
  has_many :page_views

  has_many :listings
  has_many :agents

  has_one :mail_notify, dependent: :destroy

  has_many :rooms
  has_many :roommates
  has_many :spade_passes

  has_many :client_applies


  accepts_nested_attributes_for :mail_notify

  after_create :build_default_mail_notify, :send_welcome_mail
  after_save :set_cache_id

  Roles = ["user", "editor", "admin", "office", "operation", "marketing"]

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates_presence_of :role
  validates_inclusion_of :role, in: Roles
  include RecommendHelper

  def reputable_listings
    Listing.joins(:reputations).where('reputations.account_id = ?', self.id)
    .order('reputations.id desc')
  end

  before_validation(on: :create) do
    self.init_role
  end

  def name
    "#{first_name} #{last_name}"
  end

  def cache_id
    @cache_id ||= self.id
  end

  def set_cache_id
    @cache_id = "#{self.id}-#{rand}"
  end
  def phone_number
    "#{first_phone} #{last_phone}"
  end

  def collect?(target)
    collected(target).present? ? true : false
  end

  def collected(target)
    Reputation.where(reputable: target, category: "collect", account_id: self.id).first
  end

  def room_saved?(target)
    get_room_saved(target).present? ? true : false
  end

  def get_room_saved(target)
    Reputation.where(reputable: target, category: "room", account_id: self.id).first
  end

  def building_faved?(target)
    get_building_faved(target).present? ? true : false
  end

  def get_building_faved(target)
    Reputation.where(reputable: target, category: "building", account_id: self.id).first
  end

  def has_room_postings?
    Room.find_by(account_id: self.id).present? || Roommate.find_by(account_id: self.id).present?
  end

  def role?(target_role)
    self.role == target_role.to_sym || self.role == target_role.to_s
  end

  def init_role
    self.role ||= "user"
  end

  def default_avatar_url(size = '55')
    if self.id
      img_id =  (self.id % 4) + 1
    else
      img_id  = 1
    end
    "reviews/avatars/0#{img_id}_#{size}.png"
  end

  def avatar_url
    img = read_attribute(:avatar_url)
    if img.present?
      img.sub(/^http\:/, 'https:').sub(/\?.+$/, '?height=100&width=100')
    end
  end

  def get_client_applies
    ClientApply.where(account_id: self.id)
  end

  AvatarUploader.versions.keys.each do |version|
    define_method "#{version}_image_url" do
      if self.image.blank?
        self.avatar_url || ActionController::Base.helpers.asset_path(default_avatar_url)
      else
        image = self.image.public_send version
        image.url || ActionController::Base.helpers.asset_path(default_avatar_url)
      end
    end
  end

  def origin_image_url
    if self.image.blank?
      self.avatar_url || ActionController::Base.helpers.asset_path(default_avatar_url)
    else
      image.url || ActionController::Base.helpers.asset_path(default_avatar_url)
    end
  end

  def self.find_for_facebook_oauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.save!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  include Facebook::GraphReview

  def post_review(review, review_url)
    return if facebook_token.blank?
    if review.is_neighborhood?
      post_neighborhood_review(facebook_token, review_url)
    else
      post_building_review(facebook_token, review_url)
    end
  end

  def logined_facebook?
    !!facebook_token
  end

  def facebook_token
    @facebook_token ||= begin
                          omniauth = self.account_omniauths.where(provider: 'facebook').first
                          return if omniauth.blank? || omniauth.expires_at.blank? || omniauth.token.blank?
                          if omniauth.expires_at > Time.now && omniauth.token.present?
                            omniauth.token
                          end
                        end
  end

  def bind_facebook?
    self.account_omniauths.where(provider: 'facebook').first.present?
  end

  def can_manage_site?
    self.role?("admin") ? true : false
  end
  alias_method :admin?, :can_manage_site?

  def generate_api_key!
    self.api_key = Digest::MD5.hexdigest(self.email)[0...10] + SecureRandom.hex(20)
    self.save!
  end
  def clear_api_key!
    self.api_key = nil
    self.save!
  end

  def hex_api_key
    BCrypt::Password.create(self.email + "CitySpade@nyc.us")
  end

  def hex_api_key_is?(hex)
    BCrypt::Password.new(hex) == (self.email + "CitySpade@nyc.us")
  end

  def phone_tel
    if first_phone.present? && last_phone.present?
      "#{first_phone}-#{last_phone}"
    end
  end

  def build_default_mail_notify
    build_mail_notify.save
  end

  def send_welcome_mail
   #    WelcomeMailer.notify(self).deliver
    MailNotifyWorker.perform_async(self.id, "welcome")
  end

  def become_office_account
    self.update_column(:role, "office") if self.role == 'user'
  end

  def remove_office_account
    self.update_column(:role, "user") if self.role == "office"
  end

  def add_office_token
    self.office_token = SecureRandom.hex[0,10].upcase if self.office_token.blank?
  end

  def can_have_access?
    self.role == "admin" || self.role == "operation" || self.role == "marketing" || self.role == "office"
  end

  def is_office_account?
    self.role == "office"
  end

  def is_operations?
    self.role == "operation"
  end

  def is_marketing?
    self.role == "marketing"
  end

  private :build_default_mail_notify, :send_welcome_mail

  def self.mail_notify
    Account.all.each do |account|
      mail_notify = account.mail_notify
      if mail_notify.is_recommended
        MailNotifyWorker.perform_async(account.id, :recommend, {})
      end
    end
  end

end
