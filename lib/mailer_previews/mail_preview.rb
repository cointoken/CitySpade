class MailPreview < ActionMailer::Preview

  # To preview emails go to: http://localhost:3000/rails/mailers

  def welcome_email
    WelcomeMailer.notify(Account.find(100))
  end

  def recommendation_email
    RecommendMailer.notify(Account.find(3292), :dummy_listings)
  end

  def list_with_us_email
    ListWithUsMailer.notify(ListWithUs.find(20))
  end

  def contact_email
    ContactMailer.notify(Contact.find(20))
  end
  def owner_email
    OwnerMailer.notify(Owner.first)
  end
  def search_me_email
    RoomContactMailer.search_for_me_email(SearchForMe.last)
  end
  def book_showing_email
    RoomContactMailer.book_showing_email(BookShowing.last, Listing.last(5))
  end

  def client_application
    RoomContactMailer.client_application(ClientApply.last)
  end

  def token_confirm
    RoomContactMailer.token_confirm(ClientApply.last)
  end

  def dealmoon_reply
    RoomContactMailer.dealmoon_reply("Vineeth")
  end

  def building_suggest
    RoomContactMailer.building_suggestion(SearchForMe.last)
  end

  def msg_availability
    msg_params = {:fname=>"Vineeth", :lname=>"Subbaraya", :email=>"vineeth.subbaraya@gmail.com", :wechat=>"abc", :message=>"teytrtytghgfjghdhhg kjhsdkjhfkdhskjhkjdhf djshfkhdkhkjhdfs hjdfkskjhdkjhds"}
    building = Building.find 833977
    ContactMailer.send_availability(msg_params, building)
  end

  def contact_agent
    @info = {:Message=>"hjhjgjgfjhj", :Name=>"Vineeth", :Email=>"vineeth.subbaraya@gmail.com", :Phone=>"4696622944"}
    ContactMailer.contact_agent(@info, Agent.last)
  end

  def send_receipt
    resp = {:transaction=>{:id=>"635b8fdb-9a0e-5c1c-58b6-ba04b82cb1c2", :location_id=>"CBASECOZqrZK9UpZuoPVlQyeDLMgAQ", :created_at=>"2017-03-15T18:20:35Z", :tenders=>[{:id=>"218cba81-ece0-5c98-5de8-113bea250167", :location_id=>"CBASECOZqrZK9UpZuoPVlQyeDLMgAQ", :transaction_id=>"635b8fdb-9a0e-5c1c-58b6-ba04b82cb1c2", :created_at=>"2017-03-15T18:20:35Z", :note=>"Online Transaction", :amount_money=>{:amount=>100, :currency=>"USD"}, :type=>"CARD", :card_details=>{:status=>"CAPTURED", :card=>{:card_brand=>"VISA", :last_4=>"5858"}, :entry_method=>"KEYED"}}], :product=>"EXTERNAL_API"}}
    ContactMailer.send_receipt(ClientApply.last, OpenStruct.new(resp))
  end
end
