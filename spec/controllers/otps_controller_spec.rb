# frozen_string_literal: true

require 'rails_helper'

describe OtpsController do
  WebMock.disable_net_connect!(allow_localhost: true)

  before do
    activate_authlogic
    login_as(user_authy)
  end

  let(:user_authy) do create(:user,
                             phone: '1234567891',
                             country: 'United States',
                             authy_user_id: '261071388'
                            )
  end

  describe '#login' do
    context 'when user is registered with authy' do
      before do
        get :login
      end

      it 'renders login page' do
        expect(response).to render_template :login
      end

      it 'does not authenticate user' do
        expect(session[:authenticated]).not_to eq true
      end
    end

    context 'when user is not registered with authy' do
      before do
        login_as(create(:user, authy_user_id: nil))
        get :login
      end

      it 'renders u2fs#index' do
        expect(response).to redirect_to u2fs_path
      end

      it 'does not authenticate user' do
        expect(session[:authenticated]).to eq false
      end
    end
  end

  describe '#verify_login', vcr: { cassette_name: 'authy_code_verify' } do
    context 'with invalid code'  do
      before do
        params = { otp: { verification_code: '123456', authy_user_id: 261071388, phone: '1234567891', country: 'United States' } }
        get :verify_login, params
      end

      it 'renders login page ' do
        expect(response).to render_template :login
      end

      it 'shows error message' do
        expect(request.flash[:error]).not_to be_nil
      end

      it 'does not authenticate user' do
        expect(session[:authenticated]).not_to eq true
      end
    end

    context 'with valid code' do
      before do
        params = { otp: { verification_code: '1234567', authy_user_id: 261071388, phone: '1234567891', country: 'United States' } }
        get :verify_login, params
      end

      it 'authenticates user' do
        expect(session[:authenticated]).to eq true
      end

      # Expect redirection (according to set_redirect method)
      it 'redirects' do
        expect(response.status).to eq 302
      end
    end
  end

  describe '#email_login' do
    context 'without authy user' do
      before do
        login_as(create(:user, authy_user_id: nil))
        get :email_login
      end

      it 'redirects to u2fs#index' do
        expect(response).to redirect_to u2fs_path
      end

      it 'shows error in flash messages' do
        expect(request.flash[:error]).not_to be_nil
      end

      it 'authenticates user' do
        expect(session[:authenticated]).to eq false
      end
    end

    context 'with registered authy user' do
      before do
        get :login
      end

      it 'renders login template' do
        expect(request).to render_template :login
      end

      it 'does not raise errors' do
        expect(request.flash[:error]).to be_nil
      end

      it 'keeps user unauthenticated' do
        expect(session[:authenticated]).not_to eq true
      end
    end
  end

  describe '#email' do
    it 'requires otp parameters' do
      get :email, xhr: true
      expect(JSON.parse(response.body)['error'].present?).to eq true
    end

    it 'requires phone and counry fields' do
      login_as(create(:user))
      get :email, { otp: { } }, xhr: true
      expect(JSON.parse(response.body)['error'].present?).to eq true
    end

    it 'requires user with phone and counry fields' do
      get :email, { otp: { } }, xhr: true
      expect(JSON.parse(response.body)['error'].present?).to eq false
    end

    context 'with existing authy user' do
      before do
        get :email, { otp: { } }, xhr: true
      end

      it 'does not raise errors' do
        expect(JSON.parse(response.body)['error'].present?).to eq false
      end

      it 'returns result with authy_user_id' do
        expected_result = { error: nil, id: '261071388' }.stringify_keys
        expect(JSON.parse(response.body)).to eq expected_result
      end

      it 'keeps user unauthenticated' do
        expect(session[:authenticated]).not_to eq true
      end
    end
  end

  describe '#add_phone' do
    it 'requires otp parameters' do
      get :add_phone, xhr: true
      expect(JSON.parse(response.body)['error'].present?).to eq true
    end

    it 'requires phone and country fields' do
      get :add_phone, { otp: { } }, xhr: true
      expect(JSON.parse(response.body)['error'].present?).to eq true
    end

    it 'does not verify already verified phone' do
      VCR.use_cassette('authy_user_exists', allow_playback_repeats: true) do
        get :add_phone, { otp: { phone: '1234567891', country: 'United States' } }, xhr: true
        expect(JSON.parse(response.body)['error']).to include 'Phone already verified!'
      end
    end

    context 'when new user', vcr: { cassette_name: 'authy_user_does_not_exist' } do
      before do
        get :add_phone, { otp: { phone: '1234567891', country: 'United States' } }, xhr: true
      end

      it 'verifies new user' do
        expect(session[:authenticated]).not_to eq true
      end

      it 'does not return errors' do
        expect(JSON.parse(response.body)['error'].present?).to eq false
      end
    end
  end

  describe '#verify_add_phone', vcr: { cassette_name: 'authy_code_verify' } do
    context 'with invalid code'  do
      before do
        params = { otp: { verification_code: '123456', authy_user_id: 261071388, phone: '1234567891', country: 'United States' } }
        get :verify_add_phone, params
      end

      it 'raises errors' do
        expect(JSON.parse(response.body)['error'].present?).to eq true
      end

      it 'does not authenticate user' do
        expect(session[:authenticated]).not_to eq true
      end
    end

    context 'with valid code' do
      before do
        params = { otp: { verification_code: '1234567', authy_user_id: 261071388, phone: '1234567891' } }
        get :verify_add_phone, params
      end

      it 'authenticates user' do
        expect(session[:authenticated]).to eq true
      end

      # Expect redirection (according to set_redirect method)
      it 'returns result with authy_user_id' do
        expected_result = { error: nil, success: 'true' }.stringify_keys
        expect(JSON.parse(response.body)).to eq expected_result
      end
    end

    context 'with valid code and new values' do
      before do
        country_id = Country.find_by(name: 'United States')&.id
        params = { otp: { verification_code: '1234567', authy_user_id: 261071389, phone: '1234567892', country_id: country_id } }
        get :verify_add_phone, params
      end

      it 'authenticates user' do
        expect(session[:authenticated]).to eq true
      end

      it 'saves new phone' do
        user_authy.reload
        expect(user_authy.phone).to eq '1234567892'
      end

      it 'deletes old authy user if params otp has new authy_user_id' do
        user_authy.reload
        expect(user_authy.authy_user_id).to eq '261071389'
      end
    end
  end
end
