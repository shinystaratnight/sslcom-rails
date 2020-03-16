# frozen_string_literal: true

require 'rails_helper'

describe CertificatesController do
  before :all do
    stub_roles
    stub_triggers
    stub_server_software
    create(:certificate_with_certificate_order)
  end

  describe 'find_tier before_filter' do
    it 'finds tier when passed reseller_cookie params' do
      tier_options = attributes_for(:reseller_tier, :west)
      ResellerTier.generate_tier(tier_options)

      params = {
        id: 'evucc',
        reseller_tier_key: 'west.com'
      }

      get :pricing, params
      assert_equal assigns[:tier], '-west.comtr'
    end

    it 'tier is nil when no reseller_cookie is passed' do
      params = {
        id: 'evucc'
      }

      get :pricing, params
      assert_equal assigns[:tier], nil
    end
  end
end
