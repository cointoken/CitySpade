class SeedMailNotify < ActiveRecord::Migration
  def change
    Account.all.each do |account|
      unless account.mail_notify
        account.build_mail_notify.save
      end
    end
  end
end
