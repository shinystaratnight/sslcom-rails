require 'rails_helper'

describe VerificationsController, type: :controller do
  let(:user) { create(:user) }
  let(:verification) { create(:sms_verification) }

  before do
    activate_authlogic
    login_as(user)
  end

  describe '#index' do
    before do
      get :index
    end

    it 'renders index template' do
      expect(response).to render_template :index
    end
  end
end
