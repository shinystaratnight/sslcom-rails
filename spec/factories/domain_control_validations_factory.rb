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

    factory :email_domain_control_validation do
      dcv_method { 'email' }
      identifier { Faker::Alphanumeric.alphanumeric(number: 10) }
      identifier_found { true }
      responded_at { DateTime.now }
      sent_at { DateTime.now }
      workflow_state { 'satisfied' }
      validation_compliance_id { 2 }
    end
  end
end
