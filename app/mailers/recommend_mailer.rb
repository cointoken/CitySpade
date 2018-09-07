class RecommendMailer < MailerBase
  # default from: Settings.email.noreply

  def notify(account, method_name = :recommend_listings)
    @account = account
    @recommend_records = @account.public_send method_name
    @recommend_records = @recommend_records[0...6]

    return if @recommend_records.size < 6
    mail to: to_email(account.email), subject: "#{Time.now.strftime('%B %d')} Update: 6 apartments you can't miss." do |format|
      format.html
    end
  end
end
