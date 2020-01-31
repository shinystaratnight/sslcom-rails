# frozen_string_literal: true

require 'test_helper'

describe CertificatesController do
  before do
    initialize_roles
    initialize_triggers
  end

  describe 'find_tier before_filter' do
    it 'finds tier when passed reseller_id params' do
      reseller = create(:reseller)
      create(:certificate_with_certificate_order)
      params = {
        id: 'evucc',
        reseller_id: reseller[:id]
      }

      get :pricing, params
      assert_equal assigns[:tier], reseller.ssl_account.tier_suffix
    end

    it 'tier is nil when no reseller_id is passed' do
      create(:certificate_with_certificate_order)
      params = {
        id: 'evucc'
      }

      get :pricing, params
      assert_equal assigns[:tier], nil
    end
  end
end
