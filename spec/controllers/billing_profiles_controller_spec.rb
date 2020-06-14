require 'rails_helper'

describe BillingProfilesController do
  include SessionHelper
  let!(:user) { create(:user, :sys_admin) }

  before do
    activate_authlogic
    login_as(user)
  end

  describe '#create' do
    it 'renders flash message' do
      post :create, { billing_profile: attributes_for(:billing_profile) }
      expect(flash[:notice].present?).to eq true
    end

    it 'executes successfully' do
      expect do
        post :create, { billing_profile: attributes_for(:billing_profile) }
      end.to change(BillingProfile, :count).by 1
    end
  end
end
