class WelcomeMailer < MailerBase

  def notify(account)
    @account = account
    mail to: to_email(account.email), subject: "Welcome to CitySpade - Spot your next move" do |format|
      format.html
    end
  end

  def test_mail(body)
    #mail to: 'alex@cityspade.com', cc: 'vineeth@cityspade.com', subject: "Cron Job", body: body
    mail to: 'vineeth@cityspade.com', subject: "Cron Job", body: body
  end
end
