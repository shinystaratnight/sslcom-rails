# frozen_string_literal: true

require 'test_helper'

describe CertificatesController do
  before do
    initialize_roles
    initialize_triggers
    # login(role: :reseller)
  end

  describe 'find_tier before_filter' do
    # let!(:user) { create(:user, :reseller) }
    it 'finds tier when passed reseller_id params' do
      reseller = create(:reseller)
      # binding.pry
      # reseller_id = user.ssl_account.reseller[:id]
      params = {
        reseller_id: reseller[:id]
      }

      get :pricing, params
      assert_equal assigns[:tier], reseller_id
    end
  end
end
