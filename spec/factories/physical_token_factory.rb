FactoryBot.define do
  factory :physical_token do
    workflow_state { 'received' }
  end
end
