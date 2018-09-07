class AccountOmniauth < ActiveRecord::Base
  belongs_to :account
  def self.find_omniauth_auth(res, account = nil)
    where(res.slice(:provider, :uid)).first_or_initialize.tap do |auth|
      auth.account ||= account
      unless auth.account
        account = Account.where(email: res.info.email).first_or_initialize
        account.password ||= Devise.friendly_token[0,20]
        if account.image.blank? && account.avatar_url.blank?
          account.avatar_url ||= res.info.image
        end
        account.first_name ||= res.info.first_name
        account.last_name  ||= res.info.last_name
        account.save
        auth.update_attribute(:account, account)
      end
      auth.token = res.credentials.token
      auth.expires_at = Time.at res.credentials.expires_at
      auth.save
      return auth.account
    end
  end
end
