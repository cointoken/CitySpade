require "spec_helper"

describe Api::V1::AuthController do

  render_views
  describe "POST 'register'" do
    it "should register" do
      Account.where(email: "jackielin1992@gmail.com").destroy_all
      api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"
      response.status.should == 200
    end

    it "should not register" do
      api_post :register, email: "jackielin1992@gmail.com", password: nil
      response.status.should == 422
    end
  end

  describe "POST 'login'" do
    it "should login" do
      Account.where(email: "jackielin1992@gmail.com").destroy_all
      api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"

      username = "jackielin1992@gmail.com"
      password = '$%^123456'
      client_uuid = "234242"
      client_secret = Digest::SHA1.hexdigest (
        [username, password, client_uuid, 'CitySpade'].sort.join)
      api_post :login, username: username, password: password,
        client_uuid: client_uuid, client_secret: client_secret
      response.status.should == 200
    end

    it "should not logins" do
      Account.where(email: "jackielin1992@gmail.com").destroy_all
       api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"
      username = "jackielin1992@gmail.com"
      password = ""
      client_uuid = ""
      client_secret = Digest::SHA1.hexdigest (
        username + password + client_uuid + 'CitySpade')
      api_post :login, username: username, password: password,
        client_uuid: client_uuid, client_secret: client_secret
      response.status.should == 422
    end

  end

  describe "DELETE 'logout'" do
    it "should logout" do
      Account.where(email: "jackielin1992@gmail.com").destroy_all
     api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"
      account = Account.find_by_email("jackielin1992@gmail.com")
      api_delete :logout, token: account.api_key
      response.status.should == 200
    end

    it "should not logout" do
      api_delete :logout, token: nil
      response.status.should == 401
    end
  end

  describe "GET 'forget_password'" do
    it "should find your password" do
      Account.where(email: "jackielin1992@gmail.com").destroy_all
     api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"
      api_get :forget_password, email: "jackielin1992@gmail.com"
      response.status.should == 200
    end

    it "should not find your password" do
     api_post :register, email: "jackielin1992@gmail.com", password: "$%^123456",
          first_name: "Jackie", last_name: "Lam"
      api_get :forget_password, email: "jackielin1993@gmail.com"
      response.status.should == 422
    end
  end

  describe "POST 'callback'" do
    it "should login by facebook" do
      # api_post :callback, email: "cityspade@gmail.com", uid: "fdsf24342"
      # response.status.should == 200
    end

    it "should not login by facebook" do
      # api_post :callback, email: nil, uid: '1234'
      # response.status.should == 422
    end
  end
end
