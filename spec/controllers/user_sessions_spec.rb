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
      expected_response = { failed_count: 0 }.stringify_keys
      expect(JSON.parse(response.body)).to eq expected_response
    end
  end
end
