require 'spec_helper'

describe ListingsController do
#  let (:account) { create :account }

  describe "authenticated" do
#    before (:each) {sign_in account}
    describe 'Get show' do
      it 'test' do
      end
    end
  end
  #let(:valid_attributes) { { "title" => "MyString" } }
  #let(:valid_session) { {} }

  #describe "GET index" do
  #  it "assigns all listings as @listings" do
  #    listing = Listing.create! valid_attributes
  #    get :index, {}, valid_session
  #    assigns(:listings).should eq([listing])
  #  end
  #end

  #describe "GET show" do
  #  it "assigns the requested listing as @listing" do
  #    listing = Listing.create! valid_attributes
  #    get :show, {:id => listing.to_param}, valid_session
  #    assigns(:listing).should eq(listing)
  #  end
  #end

  #describe "GET new" do
  #  it "assigns a new listing as @listing" do
  #    get :new, {}, valid_session
  #    assigns(:listing).should be_a_new(Listing)
  #  end
  #end

  #describe "GET edit" do
  #  it "assigns the requested listing as @listing" do
  #    listing = Listing.create! valid_attributes
  #    get :edit, {:id => listing.to_param}, valid_session
  #    assigns(:listing).should eq(listing)
  #  end
  #end

  #describe "POST create" do
  #  describe "with valid params" do
  #    it "creates a new Listing" do
  #      expect {
  #        post :create, {:listing => valid_attributes}, valid_session
  #      }.to change(Listing, :count).by(1)
  #    end

  #    it "assigns a newly created listing as @listing" do
  #      post :create, {:listing => valid_attributes}, valid_session
  #      assigns(:listing).should be_a(Listing)
  #      assigns(:listing).should be_persisted
  #    end

  #    it "redirects to the created listing" do
  #      post :create, {:listing => valid_attributes}, valid_session
  #      response.should redirect_to(Listing.last)
  #    end
  #  end

  #  describe "with invalid params" do
  #    it "assigns a newly created but unsaved listing as @listing" do
  #      # Trigger the behavior that occurs when invalid params are submitted
  #      Listing.any_instance.stub(:save).and_return(false)
  #      post :create, {:listing => { "title" => "invalid value" }}, valid_session
  #      assigns(:listing).should be_a_new(Listing)
  #    end

  #    it "re-renders the 'new' template" do
  #      # Trigger the behavior that occurs when invalid params are submitted
  #      Listing.any_instance.stub(:save).and_return(false)
  #      post :create, {:listing => { "title" => "invalid value" }}, valid_session
  #      response.should render_template("new")
  #    end
  #  end
  #end

  #describe "PUT update" do
  #  describe "with valid params" do
  #    it "updates the requested listing" do
  #      listing = Listing.create! valid_attributes
  #      # Assuming there are no other listings in the database, this
  #      # specifies that the Listing created on the previous line
  #      # receives the :update_attributes message with whatever params are
  #      # submitted in the request.
  #      Listing.any_instance.should_receive(:update).with({ "title" => "MyString" })
  #      put :update, {:id => listing.to_param, :listing => { "title" => "MyString" }}, valid_session
  #    end

  #    it "assigns the requested listing as @listing" do
  #      listing = Listing.create! valid_attributes
  #      put :update, {:id => listing.to_param, :listing => valid_attributes}, valid_session
  #      assigns(:listing).should eq(listing)
  #    end

  #    it "redirects to the listing" do
  #      listing = Listing.create! valid_attributes
  #      put :update, {:id => listing.to_param, :listing => valid_attributes}, valid_session
  #      response.should redirect_to(listing)
  #    end
  #  end

  #  describe "with invalid params" do
  #    it "assigns the listing as @listing" do
  #      listing = Listing.create! valid_attributes
  #      # Trigger the behavior that occurs when invalid params are submitted
  #      Listing.any_instance.stub(:save).and_return(false)
  #      put :update, {:id => listing.to_param, :listing => { "title" => "invalid value" }}, valid_session
  #      assigns(:listing).should eq(listing)
  #    end

  #    it "re-renders the 'edit' template" do
  #      listing = Listing.create! valid_attributes
  #      # Trigger the behavior that occurs when invalid params are submitted
  #      Listing.any_instance.stub(:save).and_return(false)
  #      put :update, {:id => listing.to_param, :listing => { "title" => "invalid value" }}, valid_session
  #      response.should render_template("edit")
  #    end
  #  end
  #end

  #describe "DELETE destroy" do
  #  it "destroys the requested listing" do
  #    listing = Listing.create! valid_attributes
  #    expect {
  #      delete :destroy, {:id => listing.to_param}, valid_session
  #    }.to change(Listing, :count).by(-1)
  #  end

  #  it "redirects to the listings list" do
  #    listing = Listing.create! valid_attributes
  #    delete :destroy, {:id => listing.to_param}, valid_session
  #    response.should redirect_to(listings_url)
  #  end
  #end

end
