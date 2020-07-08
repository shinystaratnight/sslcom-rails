require 'rails_helper'

describe OrdersController do
  include SessionHelper
  let!(:user) { create(:user, :owner) }
  let!(:billing_profile) { create(:billing_profile, ssl_account: user.ssl_account) }

  before do

    activate_authlogic
    login_as(user)
  end

  describe '#create' do
    before do
      post :create, { order:           { cents: 10_000 },
                      funding_source:  billing_profile.id,
                      payment_method:  'credit_card',
                      billing_profile: attributes_for(:billing_profile) }
    end

    it 'assigns order' do
      expect(assigns(:order)).to be_a Order
    end

    it 'assigns profile' do
      expect(assigns(:profile)).to be_a BillingProfile
    end

    it 'increases ssl_acount orders' do
      expect do
        post :create, { order:           { cents:  10_000 },
                        funding_source:  billing_profile.id,
                        payment_method:  'credit_card',
                        billing_profile: attributes_for(:billing_profile) }
      end.to change(Order, :count).by 1
    end

    it 'redirects to orders_path' do
      expect(response.code).to eq '302'
    end

    it 'shows flash message' do
      expect(flash[:error]).to eq nil
    end
  end
end
