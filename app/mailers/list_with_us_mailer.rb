class ListWithUsMailer < MailerBase
  default to: Proc.new { 
    #Settings.email.list_with_us.first 
    if Rails.env == 'production'
      Settings.email.list_with_us
    else
      ['cityspade@gmail.com',
       'cityspade.dev@gmail.com']
    end
  }, bcc: Settings.email.bcc

  def notify(list_with_us)
    @list_with_us = list_with_us
    mail subject: "List With Us(#{list_with_us.email})"
  end
end
