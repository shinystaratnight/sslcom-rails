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

describe UnsubscribesController do

  # This should return the minimal set of attributes required to create a valid
  # Unsubscribe. As you add validations to Unsubscribe, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all unsubscribes as @unsubscribes" do
      unsubscribe = Unsubscribe.create! valid_attributes
      get :index
      assigns(:unsubscribes).should eq([unsubscribe])
    end
  end

  describe "GET show" do
    it "assigns the requested unsubscribe as @unsubscribe" do
      unsubscribe = Unsubscribe.create! valid_attributes
      get :show, :id => unsubscribe.id.to_s
      assigns(:unsubscribe).should eq(unsubscribe)
    end
  end

  describe "GET new" do
    it "assigns a new unsubscribe as @unsubscribe" do
      get :new
      assigns(:unsubscribe).should be_a_new(Unsubscribe)
    end
  end

  describe "GET edit" do
    it "assigns the requested unsubscribe as @unsubscribe" do
      unsubscribe = Unsubscribe.create! valid_attributes
      get :edit, :id => unsubscribe.id.to_s
      assigns(:unsubscribe).should eq(unsubscribe)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Unsubscribe" do
        expect {
          post :create, :unsubscribe => valid_attributes
        }.to change(Unsubscribe, :count).by(1)
      end

      it "assigns a newly created unsubscribe as @unsubscribe" do
        post :create, :unsubscribe => valid_attributes
        assigns(:unsubscribe).should be_a(Unsubscribe)
        assigns(:unsubscribe).should be_persisted
      end

      it "redirects to the created unsubscribe" do
        post :create, :unsubscribe => valid_attributes
        response.should redirect_to(Unsubscribe.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved unsubscribe as @unsubscribe" do
        # Trigger the behavior that occurs when invalid params are submitted
        Unsubscribe.any_instance.stub(:save).and_return(false)
        post :create, :unsubscribe => {}
        assigns(:unsubscribe).should be_a_new(Unsubscribe)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Unsubscribe.any_instance.stub(:save).and_return(false)
        post :create, :unsubscribe => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested unsubscribe" do
        unsubscribe = Unsubscribe.create! valid_attributes
        # Assuming there are no other unsubscribes in the database, this
        # specifies that the Unsubscribe created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Unsubscribe.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => unsubscribe.id, :unsubscribe => {'these' => 'params'}
      end

      it "assigns the requested unsubscribe as @unsubscribe" do
        unsubscribe = Unsubscribe.create! valid_attributes
        put :update, :id => unsubscribe.id, :unsubscribe => valid_attributes
        assigns(:unsubscribe).should eq(unsubscribe)
      end

      it "redirects to the unsubscribe" do
        unsubscribe = Unsubscribe.create! valid_attributes
        put :update, :id => unsubscribe.id, :unsubscribe => valid_attributes
        response.should redirect_to(unsubscribe)
      end
    end

    describe "with invalid params" do
      it "assigns the unsubscribe as @unsubscribe" do
        unsubscribe = Unsubscribe.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Unsubscribe.any_instance.stub(:save).and_return(false)
        put :update, :id => unsubscribe.id.to_s, :unsubscribe => {}
        assigns(:unsubscribe).should eq(unsubscribe)
      end

      it "re-renders the 'edit' template" do
        unsubscribe = Unsubscribe.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Unsubscribe.any_instance.stub(:save).and_return(false)
        put :update, :id => unsubscribe.id.to_s, :unsubscribe => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested unsubscribe" do
      unsubscribe = Unsubscribe.create! valid_attributes
      expect {
        delete :destroy, :id => unsubscribe.id.to_s
      }.to change(Unsubscribe, :count).by(-1)
    end

    it "redirects to the unsubscribes list" do
      unsubscribe = Unsubscribe.create! valid_attributes
      delete :destroy, :id => unsubscribe.id.to_s
      response.should redirect_to(unsubscribes_url)
    end
  end

end
