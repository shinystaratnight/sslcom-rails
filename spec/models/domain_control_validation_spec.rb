# frozen_string_literal: true
require 'rails_helper'

describe DomainControlValidation do
  describe 'workflow' do

    context 'validation' do
      before do
        Timecop.freeze(DateTime.now)
      end

      after do
        Timecop.return
      end

      describe 'satisfied state' do
        context 'email' do
          it 'populates the correct fields' do
            dcv = FactoryBot.build(:domain_control_validation, dcv_method: 'email', workflow_state: 'new')
            dcv.satisfy!
            expect(dcv.dcv_method).to match 'email'
            expect(dcv.validation_compliance_id).to eq 2
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end
        end

        context 'http' do
          it 'populates the correct fields with csr info' do
            domain = FactoryBot.create(:domain, name: 'support.ssl.com')
            csr = FactoryBot.create(:csr, common_name: 'ssl.com')
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'http',
              workflow_state: 'new',
              certificate_name_id: domain.id,
              csr_id: csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end

          it 'populates the correct fields with certificate name info' do
            certificate_name = FactoryBot.create(:certificate_name)
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'http',
              workflow_state: 'new',
              certificate_name_id: certificate_name.id,
              csr_id: certificate_name.certificate_content.csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}\n#{certificate_name.csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "http://#{certificate_name.name}/.well-known/pki-validation/#{certificate_name.csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end
        end

        context 'https' do
          it 'populates the correct fields with csr info' do
            domain = FactoryBot.create(:domain, name: 'support.ssl.com')
            csr = FactoryBot.create(:csr, common_name: 'ssl.com')
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'https',
              workflow_state: 'new',
              certificate_name_id: domain.id,
              csr_id: csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end

          it 'populates the correct fields with certificate name info' do
            certificate_name = FactoryBot.create(:certificate_name)
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'https',
              workflow_state: 'new',
              certificate_name_id: certificate_name.id,
              csr_id: certificate_name.certificate_content.csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}\n#{certificate_name.csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "https://#{certificate_name.name}/.well-known/pki-validation/#{certificate_name.csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end
        end

        context 'cname' do
          it 'populates the necessary fields for cname' do
            domain = FactoryBot.create(:domain, name: 'support.ssl.com')
            csr = FactoryBot.create(:csr, common_name: 'ssl.com')
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'cname',
              workflow_state: 'new',
              certificate_name_id: domain.id,
              csr_id: csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{csr.dns_sha2_hash}.#{csr.ca_tag}"
            expect(dcv.address_to_find_identifier).to eq "#{csr.dns_md5_hash}.#{domain.name}"
            expect(dcv.validation_compliance_id).to eq 7
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end

          it 'populates the necessary fields for cname when cert content is present' do
            certificate_name = FactoryBot.create(:certificate_name)
            dcv = FactoryBot.build(:domain_control_validation,
              dcv_method: 'cname',
              workflow_state: 'new',
              certificate_name_id: certificate_name.id,
              csr_id: certificate_name.certificate_content.csr.id
            )

            dcv.satisfy!
            expect(dcv.identifier).to eq "#{certificate_name.csr.dns_sha2_hash}.#{certificate_name.csr.ca_tag}"
            expect(dcv.address_to_find_identifier).to eq "#{certificate_name.csr.dns_md5_hash}.#{certificate_name.name}"
            expect(dcv.validation_compliance_id).to eq 7
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(dcv.workflow_state).to match /satisfied/
          end
        end
      end
    end
  end

  context 'class methods' do
    describe 'described_class.icann_contacts' do
      it 'loads contacts from yaml file' do
        described_class.icann_contacts.should include('contact@0101domain.com')
      end
    end
  end
end
