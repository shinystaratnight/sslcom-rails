require 'test_helper'
class MerchantContactTest < ActiveSupport::TestCase
  test "migrating from mssql" do
    OldSite::MerchantContact.all.each do |mc|
      unless mc.MerchantID==0
        c_contact=CertificateContact.new
        mc.copy_attributes_to c_contact
        assert c_contact.save, "#{mc.MerchantContactID} failed this assert!" if
          c_contact.valid?
      end
    end
  end
end
