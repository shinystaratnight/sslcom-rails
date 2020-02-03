# frozen_string_literal: true

require 'test_helper'

describe CertificatesController do
  before do
    initialize_roles
    initialize_triggers
  end

  describe 'find_tier before_filter' do
    it 'finds tier when passed reseller_cookie params' do
      create(:certificate_with_certificate_order)
      tier_options = attributes_for(:reseller_tier, :west)
      ResellerTier.generate_tier(tier_options)

      params = {
        id: 'evucc',
        reseller_cookie: 'west.com'
      }

      get :pricing, params
      assert_equal assigns[:tier], '-west.comtr'
    end

    it 'tier is nil when no reseller_cookie is passed' do
      create(:certificate_with_certificate_order)
      params = {
        id: 'evucc'
      }

      get :pricing, params
      assert_equal assigns[:tier], nil
    end
  end
end
