# frozen_string_literal: true

require 'rails_helper'

describe 'User Sessions', type: :request do
  let!(:user_owner) { create(:user, :owner) }
  let!(:user_u2f) { create(:user, :u2f) }
  let(:user_superuser) { create(:user, :super_user) }

  ## Cases
  # 1. user is a super user, and must use DUO to login
  # 2. user without 2FA obligation
  # 3. user without u2f key but with default_team that requires u2f
  # 3. user with u2f key added to user account, without team that requires u2f
  # 4. user with u2f key added to user account, and team that requires u2f

  describe '#create' do
    context 'when super user' do
      # User must log in with DUO
      before do
        post user_session_path, { user_session: { login: user_superuser.login,
                                                  password: user_superuser.password,
                                                  u2f_response: '',
                                                  logout: false,
                                                  failed_count: 0 } }
        follow_redirect!
      end

      it 'is not authenticated' do
        expect(session[:authenticated]).to eq false
      end

      it 'requires DUO authentication' do
        expect(response).to redirect_to duo_user_session_url
      end
    end

    context 'when user does not have 2FA' do
      before do
        post user_session_path, { user_session: { login: user_owner.login,
                                                  password: user_owner.password,
                                                  u2f_response: '',
                                                  logout: false,
                                                  failed_count: 0 } }
      end

      it 'is authenticated' do
        expect(session[:authenticated]).to eq true
      end

      it 'gets redirected to account' do
        expect(response).to redirect_to account_url(ssl_slug: user_owner.ssl_account(:default).acct_number)
      end
    end

    context 'user with security key' do
      before do
        post user_session_path, { user_session: { login: user_u2f.login,
                                                  password: user_u2f.password,
                                                  u2f_response: '',
                                                  logout: false,
                                                  failed_count: 0 } }
      end

      it 'is not authenticated' do
        expect(session[:authenticated]).to eq false
      end

      it 'is redirected to u2f' do
        expect(response).to redirect_to new_u2f_url
      end
    end

    context 'when team has sec_type u2f, and user has security key' do
      before do
        user_u2f.ssl_account.update(sec_type: 'u2f')
        post user_session_path, { user_session: { login: user_u2f.login,
                                                  password: user_u2f.password,
                                                  u2f_response: '',
                                                  logout: false,
                                                  failed_count: 0 } }
      end

      it 'is not authenticated' do
        expect(session[:authenticated]).to eq false
      end

      it 'is redirected to u2f' do
        expect(response.headers['Location'] ).to eq new_u2f_url
      end
    end
  end
end
