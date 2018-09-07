namespace :set do
  desc "Check email in SearchForMe"
  task email_check: :environment do
    SearchForMe.where(email_valid: false).each do |record|
      begin
        if EmailVerifier.check(record.email)
          record.email_valid = true
          record.save
        end
      rescue
        arr = record.email.split("@")
        if arr[1].include? ".edu"
          record.email_valid = true
          record.save
        end
        puts record.email
      end
    end
  end
end
