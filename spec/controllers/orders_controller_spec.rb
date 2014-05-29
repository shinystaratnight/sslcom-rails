require 'spec_helper'

describe OrdersController do

  describe "Get #show" do
    it "assigns the order" do
      order = create(:order)
      get :show, id: order
      expect(assigns(:order)).to eq(order)
    end

    it "shows the certificate reference number" do
      order = create(:order)
      get :show, id: order
      expect(response.body).to have_content(order.reference_number)
    end
  end

  describe "POST #create" do

    context "successful transaction" do
      it "returns a OK 200 return code" do
        post :create, order: attributes_for(:order), billing_profile: attributes_for(:billing_profile)
        response.code.should eq("200")
      end

      it "shows the certificate reference number" do
        order = create :order
        post :create, order: attributes_for(:order), user: attributes_for(:customer), billing_profile: attributes_for(:billing_profile)
        expect(response.body).to have_content(order.reference_number)
      end

      it "renders the order page" do
        post :create, order: attributes_for(:order), billing_profile: attributes_for(:billing_profile)
        expect(response).to render_template :show
      end

      it "adds a new certificate order to the database" do
        expect{
          post :create, order: attributes_for(:order)
        }.to change(Order, :count).by(1)
      end
    end

    context "unsuccessful transaction" do
      it "redirects to the new order page" do
        post :create, order: attributes_for(:order), billing_profile: attributes_for(:billing_profile)
        expect(response).to render_template :new
      end

      it "does no add a new certificate order to the database" do
        post :create, order: attributes_for(:order)
        response.code.should eq("200")
      end

      it "displays a 'declined' message" do
      end
    end
  end
end
