require 'test_helper'
class MerchantTest < ActiveSupport::TestCase
  test "migrating from mssql" do
    OldSite::Merchant.all.each do |mc|
      unless mc.MerchantID==0
        r=mc.copy_attributes_to Registrant.new
        assert !r.company_name.blank?, "#{mc.MerchantID} failed company_name"
        assert !r.address1.blank?, "#{mc.MerchantID} failed address1"
        assert !r.city.blank?, "#{mc.MerchantID} failed city"
        assert !r.state.blank?, "#{mc.MerchantID} failed state"
        assert !r.postal_code.blank?, "#{mc.MerchantID} failed postal_code"
        assert !r.country.blank?, "#{mc.MerchantID} failed country"
      end
    end
  end
end