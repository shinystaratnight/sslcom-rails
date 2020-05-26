CertificateSubject = Struct.new(:common_name, :organization, :organization_unit, :locality, :state, :country, :san)

FactoryBot.define do
  factory :certificate_subject do
    common_name { Faker::Internet.domain_name(subdomain: [true, false].sample ) }
    organization { Faker::Company.name }
    organization_unit { "OU" }
    locality { "City" }
    state { "State" }
    country { "UK" }
    san{ [] }
  end
end
