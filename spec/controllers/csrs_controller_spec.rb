require 'rails_helper'

describe CsrsController do
  before do
    @user = FactoryBot.create(:user, :owner)
    activate_authlogic
    login_as(@user)
  end

  after do
    DomainControlValidation.destroy_all
  end

  describe 'create_new_unique_value' do
    context 'changing the csr unique value' do
      let(:csr_unique_value) { FactoryBot.create(:csr_unique_value) }
      let(:csr) { csr_unique_value.csr }

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
    context 'domain validation' do
      context 'http' do
        it 'creates a dcv via http validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(true)
          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'http', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json

          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
          expect(dcv.address_to_find_identifier).to eq "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          expect(dcv.validation_compliance_id).to eq 6
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end

        it 'does not create a dcv via http validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(nil)

          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'http', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end

      context 'https' do
        it 'creates a dcv via https validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(true)
          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'https', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json

          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
          expect(dcv.address_to_find_identifier).to eq "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          expect(dcv.validation_compliance_id).to eq 6
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end

        it 'does not create a dcv via https validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(nil)

          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'https', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end

      context 'cname' do
        it 'creates a dcv via cname validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(true)
          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'cname', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json

          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.dns_sha2_hash}.#{csr.ca_tag}"
          expect(dcv.address_to_find_identifier).to eq "#{csr.dns_md5_hash}.#{domain.name}"
          expect(dcv.validation_compliance_id).to eq 7
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end

        it 'does not create a dcv via cname validation' do
          domain = FactoryBot.create(:certificate_name)
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(nil)

          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'cname', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end

      context 'with a preexisting domain control validation' do
        it 'satisfies the previous dcv attempt' do
          domain = FactoryBot.create(:certificate_name)
          domain.domain_control_validations << create(:domain_control_validation, dcv_method: 'cname' )
          certificate_content = domain.certificate_content
          csr = certificate_content.csr
          @user.ssl_accounts << certificate_content.certificate_order.ssl_account
          CertificateName.any_instance.stubs(:dcv_verify).returns(true)

          get :verification_check, team: @user.ssl_accounts.first.ssl_slug, id: "#{csr.id}", dcv_protocol: 'cname', dcv: "certificate_name:#{domain.name}", new_name: "#{domain.name}", ref: "#{certificate_content.ref}", format: :json

          dcv = DomainControlValidation.last
          expect(domain.domain_control_validations.count).to eq 1
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.dns_sha2_hash}.#{csr.ca_tag}"
          expect(dcv.address_to_find_identifier).to eq "#{csr.dns_md5_hash}.#{domain.name}"
          expect(dcv.validation_compliance_id).to eq 7
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end
      end
    end

    context 'domain prevalidation' do
      context 'http' do
        it 'creates a dcv via http validation' do
          domain = FactoryBot.create(:domain, name: 'support.ssl.com')
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('http', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'http', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json

          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
          expect(dcv.address_to_find_identifier).to eq "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          expect(dcv.validation_compliance_id).to eq 6
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end

        it 'does not create a dcv via http validation' do
          domain = FactoryBot.create(:domain, name: Faker::Internet.domain_name)
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('http', dcv_options).returns(nil)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'http', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end

      context 'https' do
        it 'creates a dcv via https validation' do
          domain = FactoryBot.create(:domain, name: 'support.ssl.com')
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('https', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'https', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
          expect(dcv.address_to_find_identifier).to eq "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
          expect(dcv.validation_compliance_id).to eq 6
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end

        it 'does not create a dcv via https validation' do
          domain = FactoryBot.create(:domain, name: Faker::Internet.domain_name)
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('https', dcv_options).returns(nil)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'https', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end

      context 'cname' do
        it 'creates a dcv via cname validation (cname)' do
          domain = FactoryBot.create(:domain, name: 'support.ssl.com')
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('cname', dcv_options).returns(true)
          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'cname', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json

          dcv = DomainControlValidation.last
          expect(DomainControlValidation.count).to eq 1
          expect(dcv.identifier).to eq "#{csr.dns_sha2_hash}.#{csr.ca_tag}"
          expect(dcv.address_to_find_identifier).to eq "#{csr.dns_md5_hash}.#{domain.name}"
          expect(dcv.validation_compliance_id).to eq 7
          expect(dcv.identifier_found).to eq true
          expect(dcv.workflow_state).to match /satisfied/
        end


        it 'does not create a dcv if verification fails (cname)' do
          domain = FactoryBot.create(:domain, name: Faker::Internet.domain_name)
          csr = FactoryBot.create(:csr, common_name: 'ssl.com')
          @user.ssl_accounts << csr.ssl_account
          dcv_options = {
              https_dcv_url: "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              http_dcv_url: "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt",
              cname_origin: "#{csr.dns_md5_hash}.#{domain.name}",
              cname_destination: "#{csr.cname_destination}",
              csr: csr,
              ca_tag: csr.ca_tag
            }

          ssl_slug = @user.ssl_accounts.first.ssl_slug
          CertificateName.expects(:dcv_verify).with('cname', dcv_options).returns(nil)

          get :verification_check, team: ssl_slug, id: csr.id, dcv_protocol: 'cname', choose_cn: "#{domain.id}", selected_csr: "#{csr.id}", format: :json
          expect(DomainControlValidation.count).to eq 0
        end
      end
    end
  end
end
