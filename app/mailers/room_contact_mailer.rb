class RoomContactMailer < ActionMailer::Base
  default from: Settings.email.noreply
  def contact_email(email, subject, body, description, room)
    @body = body
    @description = description
    address = Mail::Address.new email
    mail  to: room.account.email, cc: address.format, bcc: "cityspade@gmail.com", subject: subject
  end

  def search_for_me_email(form_info)
    @form_info = form_info
    mail  to: "pr@cityspade.com", cc: "chloe@cityspade.com", subject: "Search For Me"
  end

  def dealmoon_reply(name, email)
    @name = name
    attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/logo/City-logo2.png")
    attachments.inline['qrcode.png'] = File.read("#{Rails.root}/app/assets/images/mail/city-qrcode.png")
    mail from: "mufan@cityspade.com", to: email, subject: "CitySpade租房咨询回复"
  end

  def book_showing_email(booking, listings, info)
    @booking = booking
    @listings = listings
    @info = info
    mail to: "kiran@cityspade.com", cc: booking.email, bcc:"vineeth@cityspade.com", subject: "Booking Confirmation"
  end

  def client_application(info)
    @info = info
    #@info.documents.each do |doc|
    #  attachments["#{File.basename(doc.name.path)}"] = doc.name.read
    #end
    subject = "Application - #{@info[:first_name]} #{@info[:last_name]} [ #{@info[:building]} #{@info[:unit]} ]"
    if Rails.env.production?
      mail to: "apply@cityspade.com", subject: subject
    else
      mail to: "vineeth@cityspade.com", subject: subject
    end
  end

  def token_confirm(info)
    @info = info
    subject = "Application Confirmation"
    mail to: "#{info.email}", subject: subject
  end

  def building_suggestion(client)
    @client = client
    mail from: "CitySpade<contact@cityspade.com>", to: "#{client.email}", subject: "Find your dream home."
  end
end
