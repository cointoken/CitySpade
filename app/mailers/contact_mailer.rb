class ContactMailer < MailerBase
  # default from: Settings.email.contact
  default to: [Settings.email.contact, 'kiran.chen@cityspade.com'],
    bcc: Settings.email.bcc

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.contact_mailer.notify.subject
  #
  def notify(contact)
    @contact = contact
    mail to: "dina.yang@cityspade.com", reply_to: contact.email, subject: contact.subject
  end

  def send_message_to_agent(contact)
    @agent = contact['type'].camelize.constantize.find contact['agent_id']
    @contact = contact
    mail to: to_email(@agent.email),
      reply_to: contact['from_email'],
      subject: 'Someone is interested in your listing!'
  end

  def verify_office_account(account)
    @account = account
    mail to: to_email(account.email), subject: "Verify Account" do |format|
      format.text
    end
  end

  def send_flash_email(contact)
    @contact = contact
    mail from: Settings.email.noreply, to: contact['agent'], bcc: "alex@cityspade.com", subject: "Someone is interested in the deal"
  end

  def send_mail_building(info, docs)
    #docs = ClientApply.find(info[:client_id]).documents
    arr = info[:to_email].split(",")
    docs.each do |doc_id|
      doc = Document.find doc_id
      attachments["#{File.basename(doc.name.path)}"] = doc.name.read
    end
    mail from: info[:from_email], to: arr[0], cc: arr[1..arr.length-1], bcc: "apply@cityspade.com", subject: info[:subject], body: info[:msg_body]
  end

  def send_receipt(client,resp, subject)
    Time.zone = 'Eastern Time (US & Canada)'
    @client = client
    resp = resp.transaction.tenders.first
    paytime = resp.created_at
    @paytime = Time.zone.parse(paytime).strftime("%m/%d/%Y %H:%M:%S %Z")
    @resp = resp
    mail from: "apply@cityspade.com", to: @client.email, bcc: "apply@cityspade.com", subject: subject
    #mail from: "vineeth@cityspade.com", to: @client.email, subject: "Application Fee Receipt"
  end

  def send_cutedivide(client)
    @client = client
    mail from: "apply@cityspade.com", to: "tina@cityspade.com", subject: "Cutedivide Payment"
  end

  def send_availability(msg_params, building)
    @building = building
    @fname = msg_params[:fname]
    @lname = msg_params[:lname]
    @email = msg_params[:email]
    @wechat = msg_params[:wechat]
    @message = msg_params[:message]
    mail to: "pr@cityspade.com", cc: "chloe@cityspade.com", subject: "Building Availability"
  end

  def contact_agent(info, agent)
    @info = info
    mail to: agent.email, subject: "Agent Contact" 
  end

end
