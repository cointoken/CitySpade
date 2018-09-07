namespace :db do
  namespace :sessions do
    desc "Clean up expired Active Record sessions"
    task :clean_expired => :environment do
      Rails.logger.info "Cleaning up expired sessions..."
      time = ENV['EXPIRED_AT'] || 1.month.ago.to_s(:db)
      rows = ActiveRecord::SessionStore::Session.delete_all ["updated_at < ?", time]
      Rails.logger.info "Expired sessions cleanup: #{rows} session row(s) deleted."
    end
  end
end

