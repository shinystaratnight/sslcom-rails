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

require 'test_helper'

describe DomainControlValidation do
  subject { DomainControlValidation.new }

  context 'class methods' do
    describe 'DomainControlValidation.icann_contacts' do
      it 'loads contacts from yaml file' do
        assert_includes(DomainControlValidation.icann_contacts, 'contact@0101domain.com')
      end
    end
  end
end
