require 'spec_helper'

describe BlogsController do

  let(:blog) { create :blog}

  describe "unauthenticated" do
    describe "GET index" do
      it "access" do
        get 'index'
        response.should be_success
      end
    end

    describe "GET show" do
      it "assigns the requested blog" do
        blog
        get 'show', {id: blog.to_param}
        assigns(:blog).should eq(blog)
      end
    end
  end

end
