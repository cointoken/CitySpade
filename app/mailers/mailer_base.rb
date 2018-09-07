class MailerBase  < ActionMailer::Base
  default from: Settings.email.noreply,
    bcc: Settings.email.bcc

  def to_email(email)
    ## for showmetherent.com
    if Rails.env.production? || email =~ /showmetherent/
      email
    else
      'cityspade.dev@gmail.com'
      # Settings.email.bcc
    end
  end
end
