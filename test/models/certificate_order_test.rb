# frozen_string_literal: true

require 'test_helper'

describe CertificateOrder do
  before(:all) do
    initialize_roles
    initialize_triggers
  end

  describe 'search_with_csr scope' do
    configurable_filters = {
      common_name: Faker::Internet.domain_name,
      organization: Faker::Company.name,
      organization_unit: Faker::Commerce.department,
      address: Faker::Address.street_address,
      state: Faker::Address.state,
      postal_code: Faker::Address.postcode,
      # subject_alternative_names: nil,
      locality: Faker::Address.city,
      country: Faker::Address.country,
      # signature: nil,
      # fingerprint: nil,
      # strength: nil,
      expires_at: 300.days.from_now,
      # login: nil,
      email: Faker::Internet.email,
      # product: nil,
      decoded: true,
      is_test: true,
      # order_by_csr: nil,
      # physical_tokens: nil,
      # issued_at: nil,
      # notes: nil,
      # ref: nil,
      # external_order_number: nil,
      status: nil,
      duration: 365
      # co_tags: nil,
      # cc_tags: nil,
      # folder_ids: nil
    }
    _dyanmic_filters = %i[created_at account_number]

    configurable_filters.each do |name, value|
      order = create(:certificate_order, "#{name}": value)
      it "filters by #{name}" do
        query = "#{name}=#{value}"
        puts query
        queried = CertificateOrder.search_with_csr(query)
        assert_equal(queried.include?(order), false)
      end
    end
  end
end
