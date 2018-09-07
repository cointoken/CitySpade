require 'spec_helper'

describe ReviewsController do
  include Support::Session
  let(:account) {
    create :account
  }
  let(:valid_attributes) { {
    address: "Soho",
    building_name: "Soho",
    city: "New York",
    state: "NY",
    review_type: "neighborhood",
    account_id: account.id,
    display_name: "Json",
    review_places_attributes: []
  } }

  describe "unauthenticated" do
    describe "GET index" do
      it "assigns all reviews as @reviews" do
        review = Review.create! valid_attributes
        get :index, {}
        assigns(:reviews).should eq([review])
      end
    end

    describe "GET show" do
      it "assigns the requested review as @review" do
        review = Review.create! valid_attributes
        get :show, {:id => review.to_param}
        assigns(:review).should eq(review)
      end
    end
  end

  describe "authenticated" do
    before (:each) { sign_in account }

    describe "GET new" do
      it "assigns a new review as @review" do
        get :new, {}
        assigns(:review).should be_a_new(Review)
      end
    end

    describe "GET edit" do
      it "assigns the requested review as @review" do
        review = Review.create! valid_attributes
        get :edit, {:id => review.to_param}
        assigns(:review).should eq(review)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Review" do
          expect {
            post :create, {:review => valid_attributes}
          }.to change(Review, :count).by(1)
        end

        it "assigns a newly created review as @review" do
          post :create, {:review => valid_attributes}
          assigns(:review).should be_a(Review)
          assigns(:review).should be_persisted
        end

        it "redirects to the created review" do
          post :create, {:review => valid_attributes}
          response.should redirect_to(Review.unscoped.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved review as @review" do
          # Trigger the behavior that occurs when invalid params are submitted
          Review.any_instance.stub(:save).and_return(false)
          post :create, {:review => { "address" => "invalid value" }}
          assigns(:review).should be_a_new(Review)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          Review.any_instance.stub(:save).and_return(false)
          post :create, {:review => { "address" => "invalid value" }}
          response.should render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested review" do
          review = Review.create! valid_attributes
          Review.any_instance.should_receive(:update).with({ "address" => "New address" })
          put :update, {:id => review.to_param, :review => { "address" => "New address" }}
        end

        it "assigns the requested review as @review" do
          review = Review.create! valid_attributes
          put :update, {:id => review.to_param, :review => valid_attributes}
          assigns(:review).should eq(review)
        end

        it "redirects to the review" do
          review = Review.create! valid_attributes
          put :update, {:id => review.to_param, :review => valid_attributes}
          response.should redirect_to(review)
        end
      end

      describe "with invalid params" do
        it "assigns the review as @review" do
          review = Review.create! valid_attributes
          Review.any_instance.stub(:save).and_return(false)
          put :update, {:id => review.to_param, :review => { "address" => "" }}
          assigns(:review).should eq(review)
        end

        it "re-renders the 'edit' template" do
          review = Review.create! valid_attributes
          Review.any_instance.stub(:save).and_return(false)
          put :update, {:id => review.to_param, :review => { "address" => "" }}
          response.should render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested review" do
        review = Review.create! valid_attributes
        expect {
          delete :destroy, {:id => review.to_param}
        }.to change(Review, :count).by(-1)
      end

      it "redirects to the reviews list" do
        review = Review.create! valid_attributes
        delete :destroy, {:id => review.to_param}
        response.should redirect_to(reviews_url)
      end
    end

    describe "Get collect" do
    end

    describe "Get uncollect" do
    end

  end
end
