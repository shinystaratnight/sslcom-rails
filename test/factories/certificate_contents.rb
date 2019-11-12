FactoryBot.define do
  factory :certificate_content do
    csr @nonwildcard_csr
  end
end
