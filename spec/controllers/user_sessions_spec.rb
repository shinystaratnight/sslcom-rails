# frozen_string_literal: true

require 'rails_helper'

describe UserSessionsController do
  let!(:user_owner) { create(:user, :owner) }
  let!(:user_u2f) { create(:user, :u2f) }
  describe 'login without 2FA' do
    before do
      login_params = {
        user_session: {
          login: user_owner.login,
          password: user_owner.password,
          failed_count: 0
        }
      }

      post :user_login, login_params
    end

    it 'renders response' do
      expected_response = { failed_count: "0" }.stringify_keys
      expect(JSON.parse(response.body)).to eq expected_response
    end
  end

  describe 'login with 2FA' do
    before do
      login_params = {
        user_session: {
          login: user_u2f.login,
          password: user_u2f.password,
          failed_count: 0
        }
      }

      post :user_login, login_params
    end

    it 'sets u2f values' do
      expect(user_u2f.u2fs.count).to eq 1
      expect(assigns(:result_obj)).to have_key(:app_id)
      expect(assigns(:result_obj)).to have_key(:sign_requests)
      expect(assigns(:result_obj)).to have_key(:challenge)
      expect(assigns(:result_obj)).to have_key(:failed_count)
    end
  end
end
