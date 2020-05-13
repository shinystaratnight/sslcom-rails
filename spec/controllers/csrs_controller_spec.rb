require 'rails_helper'

describe CsrsController do
  before do
    @user = FactoryBot.create(:user, :owner)
    activate_authlogic
    login_as(@user)
  end

  describe 'create_new_unique_value' do
    context 'changing the csr unique value' do
      let(:csr_unique_value) { FactoryBot.create(:csr_unique_value)}
      let(:csr) { csr_unique_value.csr}

      before(:each) do
        CsrUniqueValue.destroy_all
        @user.ssl_accounts << csr.ssl_account
      end

      it 'changes the csr unique value to a new unique value' do
        post :create_new_unique_value, team: @user.ssl_accounts.first.ssl_slug, id: csr.id, new_unique_value: 'abcde1234xyz', format: :json
        expect(CsrUniqueValue.last.unique_value).to eq 'abcde1234xyz'
        expect(CsrUniqueValue.count).to eq 2
      end

      it 'does not allow the same value to be used twice' do
        post :create_new_unique_value, team: @user.ssl_accounts.first.ssl_slug, id: csr.id, new_unique_value: csr_unique_value.unique_value, format: :json
        expect(CsrUniqueValue.all.map(&:unique_value).count { |csr_uniqe_value| csr_uniqe_value == csr_unique_value.unique_value }).to eq 1
        expect(CsrUniqueValue.count).to eq 1
      end

      it 'cannot use any previous csr unique value' do
        post :create_new_unique_value, team: @user.ssl_accounts.first.ssl_slug, id: csr.id, new_unique_value: 'abcde1234xyz', format: :json
        expect(CsrUniqueValue.last.unique_value).to eq 'abcde1234xyz'
        expect(CsrUniqueValue.count).to eq 2

        post :create_new_unique_value, team: @user.ssl_accounts.first.ssl_slug, id: csr.id, new_unique_value: csr_unique_value.unique_value, format: :json
        expect(CsrUniqueValue.count).to eq 2
      end
    end
  end

  describe 'verification_check' do
    context 'domain prevalidation' do
      let(:user) { FactoryBot.create(:user, :owner) }
      let(:domain) { FactoryBot.create(:domain, name: 'support.ssl.com') }
      let(:csr) { FactoryBot.create(:csr, common_name: 'ssl.com') }
      let(:dcv_options) do
        {
          https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
          http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
          cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
          cname_destination: "#{csr.cname_destination}",
          csr: csr,
          ca_tag: csr.ca_tag
        }
      end

      before(:each) do
        @user.ssl_accounts << csr.ssl_account
      end

      before(:each) do
        DomainControlValidation.destroy_all
      end

      context 'success cases' do
        it 'successfully creates a dcv via http validation (http)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('http', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'http', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 1
          expect(DomainControlValidation.last.workflow_state).to match /satisfied/
        end

        it 'successfully creates a dcv via https validation (https)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('https', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'https', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 1
          expect(DomainControlValidation.last.workflow_state).to match /satisfied/
        end

        it 'successfully creates a dcv via cname validation (cname)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('cname', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'cname', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 1
          expect(DomainControlValidation.last.workflow_state).to match /satisfied/
        end
      end

      context 'failure cases' do
        it 'does not create a dcv if verification fails (http)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('http', dcv_options).returns(nil)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'http', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end

        it 'does not create a dcv if verification fails (https)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('https', dcv_options).returns(nil)
          get :verification_check, team: user.ssl_accounts.first.ssl_slug, id: csr.id, dcv_protocol: 'https', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end

        it 'does not create a dcv if verification fails (cname)' do
          ssl_slug = user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('cname', dcv_options).returns(nil)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'cname', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end
    end
  end
end
