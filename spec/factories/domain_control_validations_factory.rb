FactoryBot.define do
  factory :domain_control_validation do
    dcv_method { 'https' }
    email_address {}
    candidate_addresses {}
    subject {}
    address_to_find_identifier {}
    identifier {}
    identifier_found {}
    responded_at {}
    sent_at {}
    workflow_state {}
    failure_action {}
    validation_compliance_id {}
    validation_compliance_date {}
  end
end
