class SystemMailer < MailerBase

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_admin.notice.subject
  #
  def notice(title, message)
    @message = message
    mail to: Settings.email.system, subject: title
  end
end
