require 'spec_helper'

describe Admin::BlogsController do
  let(:blog) { create :blog}
  let(:admin) { create :admin}

  describe "authenticated" do
    before (:each) {sign_in admin}
    let(:valid_attributes) { { title: "MyString", content: "My Text", account_id: admin.id } }

    describe "GET index" do
      it "access" do
        get 'index'
        response.should be_success
      end
    end

    describe "GET new" do
      it "assigns a new blog as @blog" do
        get :new
        assigns(:blog).should be_a_new(Blog)
      end
    end

    describe "GET edit" do
      it "assigns the requested blog as @blog" do
        blog = Blog.create! valid_attributes
        get :edit, {:id => blog.to_param}
        assigns(:blog).should eq(blog)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Blog" do
          expect {
            post :create, {:blog => valid_attributes}
          }.to change(Blog, :count).by(1)
        end

        it "assigns a newly created blog as @blog" do
          post :create, {:blog => valid_attributes}
          assigns(:blog).should be_a(Blog)
          assigns(:blog).should be_persisted
        end

        it "redirects to the created blog" do
          post :create, {:blog => valid_attributes}
          response.should redirect_to(Blog.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved blog as @blog" do
          # Trigger the behavior that occurs when invalid params are submitted
          Blog.any_instance.stub(:save).and_return(false)
          post :create, {:blog => { "title" => "invalid value" }}
          assigns(:blog).should be_a_new(Blog)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          Blog.any_instance.stub(:save).and_return(false)
          post :create, {:blog => { "title" => "invalid value" }}
          response.should render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested blog" do
          blog = Blog.create! valid_attributes
          # Assuming there are no other blogs in the database, this
          # specifies that the Blog created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          Blog.any_instance.should_receive(:update).with({ "title" => "Second String" })
          put :update, {:id => blog.to_param, :blog => { "title" => "Second String" }}
        end

        it "assigns the requested blog as @blog" do
          blog = Blog.create! valid_attributes
          put :update, {:id => blog.to_param, :blog => valid_attributes}
          assigns(:blog).should eq(blog)
        end

        it "redirects to the blog" do
          blog = Blog.create! valid_attributes
          put :update, {:id => blog.to_param, :blog => valid_attributes}
          response.should redirect_to(blog)
        end
      end

      describe "with invalid params" do
        it "assigns the blog as @blog" do
          blog = Blog.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          Blog.any_instance.stub(:save).and_return(false)
          put :update, {:id => blog.to_param, :blog => { "title" => "invalid value" }}
          assigns(:blog).should eq(blog)
        end

        it "re-renders the 'edit' template" do
          blog = Blog.create! valid_attributes
          # Trigger the behavior that occurs when invalid params are submitted
          Blog.any_instance.stub(:save).and_return(false)
          put :update, {:id => blog.to_param, :blog => { "title" => "invalid value" }}
          response.should render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested blog" do
        blog = Blog.create! valid_attributes
        expect {
          delete :destroy, {:id => blog.to_param}
        }.to change(Blog, :count).by(-1)
      end

      it "redirects to the blogs list" do
        blog = Blog.create! valid_attributes
        delete :destroy, {:id => blog.to_param}
        response.should redirect_to(admin_blogs_url)
      end
    end
  end
end
