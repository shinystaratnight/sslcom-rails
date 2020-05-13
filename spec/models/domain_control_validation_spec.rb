# frozen_string_literal: true

# == Schema Information
#
# Table name: domain_control_validations
#
#  id                         :integer          not null, primary key
#  address_to_find_identifier :string(255)
#  candidate_addresses        :text(65535)
#  dcv_method                 :string(255)
#  email_address              :string(255)
#  failure_action             :string(255)
#  identifier                 :string(255)
#  identifier_found           :boolean
#  responded_at               :datetime
#  sent_at                    :datetime
#  subject                    :string(255)
#  validation_compliance_date :datetime
#  workflow_state             :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  certificate_name_id        :integer
#  csr_id                     :integer
#  csr_unique_value_id        :integer
#  validation_compliance_id   :integer
#
# Indexes
#
#  index_domain_control_validations_on_3_cols                    (certificate_name_id,email_address,dcv_method)
#  index_domain_control_validations_on_3_cols(2)                 (csr_id,email_address,dcv_method)
#  index_domain_control_validations_on_certificate_name_id       (certificate_name_id)
#  index_domain_control_validations_on_csr_id                    (csr_id)
#  index_domain_control_validations_on_csr_unique_value_id       (csr_unique_value_id)
#  index_domain_control_validations_on_id_csr_id                 (id,csr_id)
#  index_domain_control_validations_on_subject                   (subject)
#  index_domain_control_validations_on_validation_compliance_id  (validation_compliance_id)
#  index_domain_control_validations_on_workflow_state            (workflow_state)
#

require 'rails_helper'

describe DomainControlValidation do
  describe 'workflow' do

    context 'domain prevalidation' do
      before do
        Timecop.freeze(DateTime.now)
      end

      after do
        Timecop.return
      end

      describe 'satisfied state' do
        let(:csr) { FactoryBot.create(:csr, common_name: 'ssl.com') }
        let(:domain) { FactoryBot.create(:domain, name: 'support.ssl.com') }
        let(:dcv) do
          FactoryBot.build(:domain_control_validation,
            dcv_method: '',
            candidate_addresses: nil,
            failure_action: 'ignore',
            certificate_name_id: domain.id,
            csr_id: csr.id,
            workflow_state: 'new'
          )
        end

        context 'email code' do
          it 'prevalidates a domain based on email submission' do
            dcv.dcv_method = 'email'
            dcv.satisfy!
            expect(dcv.dcv_method).to match 'email'
            expect(dcv.validation_compliance_id).to eq 2
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(DomainControlValidation.last.workflow_state).to match /satisfied/
          end
        end

        context 'csr validation' do
          before(:each) do
            DomainControlValidation.destroy_all
          end

          it 'populates the necessary fields for http' do
            csr.signed_certificates.destroy_all

            dcv.dcv_method = 'http'
            dcv.satisfy!
            expect(dcv.dcv_method).to match 'http'
            expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "http://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(DomainControlValidation.last.workflow_state).to match /satisfied/
          end

          it 'populates the necessary fields for https' do
            csr.signed_certificates.destroy_all

            dcv.dcv_method = 'https'
            dcv.satisfy!
            expect(dcv.dcv_method).to match 'https'
            expect(dcv.identifier).to eq "#{csr.sha2_hash}\n#{csr.ca_tag}\n#{csr.unique_value}"
            expect(dcv.address_to_find_identifier).to eq "https://#{domain.name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
            expect(dcv.validation_compliance_id).to eq 6
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(DomainControlValidation.last.workflow_state).to match /satisfied/
          end

          it 'populates the necessary fields for cname' do
            csr.signed_certificates.destroy_all

            dcv.dcv_method = 'cname'
            dcv.satisfy!
            expect(dcv.dcv_method).to match 'cname'
            expect(dcv.identifier).to eq "#{csr.dns_sha2_hash}.#{csr.ca_tag}"
            expect(dcv.address_to_find_identifier).to eq "#{csr.dns_md5_hash}.#{domain.name}"
            expect(dcv.validation_compliance_id).to eq 7
            expect(dcv.identifier_found).to eq true
            expect(dcv.responded_at).to eq DateTime.now
            expect(DomainControlValidation.last.workflow_state).to match /satisfied/
          end
        end
      end
    end
  end

  context 'class methods' do
    describe 'DomainControlValidation.icann_contacts' do
      it 'loads contacts from yaml file' do
        described_class.icann_contacts.should include('contact@0101domain.com')
      end
    end
  end
end
