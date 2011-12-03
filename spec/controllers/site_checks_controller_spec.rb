require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe SiteChecksController do

  # This should return the minimal set of attributes required to create a valid
  # SiteChecker. As you add validations to SiteChecker, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all site_checks as @site_checks" do
      site_checker = SiteChecker.create! valid_attributes
      get :index
      assigns(:site_checks).should eq([site_checker])
    end
  end

  describe "GET show" do
    it "assigns the requested site_checker as @site_checker" do
      site_checker = SiteChecker.create! valid_attributes
      get :show, :id => site_checker.id.to_s
      assigns(:site_checks).should eq(site_checker)
    end
  end

  describe "GET new" do
    it "assigns a new site_checker as @site_checker" do
      get :new
      assigns(:site_checks).should be_a_new(SiteChecker)
    end
  end

  describe "GET edit" do
    it "assigns the requested site_checker as @site_checker" do
      site_checker = SiteChecker.create! valid_attributes
      get :edit, :id => site_checker.id.to_s
      assigns(:site_checks).should eq(site_checker)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new SiteChecker" do
        expect {
          post :create, :site_checks => valid_attributes
        }.to change(SiteChecker, :count).by(1)
      end

      it "assigns a newly created site_checker as @site_checker" do
        post :create, :site_checks => valid_attributes
        assigns(:site_checks).should be_a(SiteChecker)
        assigns(:site_checks).should be_persisted
      end

      it "redirects to the created site_checker" do
        post :create, :site_checks => valid_attributes
        response.should redirect_to(SiteChecker.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved site_checker as @site_checker" do
        # Trigger the behavior that occurs when invalid params are submitted
        SiteChecker.any_instance.stub(:save).and_return(false)
        post :create, :site_checks => {}
        assigns(:site_checks).should be_a_new(SiteChecker)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        SiteChecker.any_instance.stub(:save).and_return(false)
        post :create, :site_checks => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested site_checker" do
        site_checker = SiteChecker.create! valid_attributes
        # Assuming there are no other site_checks in the database, this
        # specifies that the SiteChecker created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        SiteChecker.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => site_checker.id, :site_checks => {'these' => 'params'}
      end

      it "assigns the requested site_checker as @site_checker" do
        site_checker = SiteChecker.create! valid_attributes
        put :update, :id => site_checker.id, :site_checks => valid_attributes
        assigns(:site_checks).should eq(site_checker)
      end

      it "redirects to the site_checker" do
        site_checker = SiteChecker.create! valid_attributes
        put :update, :id => site_checker.id, :site_checks => valid_attributes
        response.should redirect_to(site_checker)
      end
    end

    describe "with invalid params" do
      it "assigns the site_checker as @site_checker" do
        site_checker = SiteChecker.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        SiteChecker.any_instance.stub(:save).and_return(false)
        put :update, :id => site_checker.id.to_s, :site_checks => {}
        assigns(:site_checks).should eq(site_checker)
      end

      it "re-renders the 'edit' template" do
        site_checker = SiteChecker.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        SiteChecker.any_instance.stub(:save).and_return(false)
        put :update, :id => site_checker.id.to_s, :site_checks => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested site_checker" do
      site_checker = SiteChecker.create! valid_attributes
      expect {
        delete :destroy, :id => site_checker.id.to_s
      }.to change(SiteChecker, :count).by(-1)
    end

    it "redirects to the site_checks list" do
      site_checker = SiteChecker.create! valid_attributes
      delete :destroy, :id => site_checker.id.to_s
      response.should redirect_to(site_checks_url)
    end
  end

end
