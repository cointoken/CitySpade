class OwnerMailer < MailerBase
  default to: Proc.new { 
    #Settings.email.list_with_us.first 
    if Rails.env == 'production'
      Settings.email.list_with_us
    else
      ['cityspade@gmail.com',
       'cityspade.dev@gmail.com']
    end
  }, bcc: Settings.email.bcc

  def notify(owner)
    @owner = owner
    mail subject: "List With Us Property Owner(#{owner.email})"
  end
end
