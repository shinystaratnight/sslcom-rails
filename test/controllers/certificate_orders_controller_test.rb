require 'test_helper'

describe CertificateOrdersController do
  # Note to developers: Extract this logic into cleaner FactoryBot setup
  before do
    unless ReminderTrigger.count == 5
      (1..5).to_a.each { |i| ReminderTrigger.create(id: i, name: i) }
    end

    unless Role.count == 11
      create(:role, :account_admin)
      create(:role, :billing)
      create(:role, :installer)
      create(:role, :owner)
      create(:role, :reseller)
      create(:role, :super_user)
      create(:role, :sysadmin)
      create(:role, :users_manager)
      create(:role, :validations)
      create(:role, :ra_admin)
      create(:role, :individual_certificate)
    end

    @user = create(:user, :owner)
    login_as(@user)
  end

  describe 'update_csr' do
    it 'should reject numerical ips' do

      certificate = create(:certificate_with_certificate_order)
      co = build(:certificate_order)
      co.sub_order_items << certificate.product_variant_items.first.sub_order_item
      co.ssl_account.users << @user
      co.certificate_contents << build(:certificate_content)
      order = build(:order)
      order.certificate_orders << co
      order
      co.save
      params = {"utf8"=>"✓", "authenticity_token"=>"QuE5zzfdW7uBm15oHVf98s9yR1/Wb4eDFHgqx1vd0gamepQUbvCj8qsGqsuJ+YnpmHkuIAwd/FetIYjitC7Y0Q==",
        "certificate"=>{"product"=>"ev"},
        "order"=>{"order_description"=>"", "adjustment_amount"=>"0", "wildcard_count"=>"0", "nonwildcard_count"=>"0", "wildcard_amount"=>"0", "nonwildcard_amount"=>"0"},
        "certificate_order"=>{"has_csr"=>"true", "certificate_contents_attributes"=> {"0"=>{"signing_request"=>"-----BEGIN CERTIFICATE REQUEST-----\r\nMIICsjCCAZoCAQAwbTELMAkGA1UEBhMCVVMxGDAWBgNVBAMMDzEwNi4yNTUuMjEy\r\nLjEyMzEQMA4GA1UEBwwHSG91c3RvbjEQMA4GA1UECgwHU1NMLmNvbTEOMAwGA1UE\r\nCAwFVGV4YXMxEDAOBgNVBAsMB1NTTC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB\r\nDwAwggEKAoIBAQCf72h5es8CmYtOKdPHkW+GTesKbaXpsh4zlxFMvJcGA64O+4Y2\r\ntdTpQvDY4q3rQrRESqkeZfd0lTPzt4dis896loFKN+W74lqGqa8VQicWSWRB+5EM\r\n9z2UHloZYmz/IQmhNRUcuWzMCZjDOd7tknzv46ZuVBmfrPGIdajiH86+f58Nlo4C\r\nbU02zasWfNsSME7z+goxoYGN4ks2Kl9ElWo09lJzWk0vC8CnZMRCdktDJ4dS6T2E\r\nPJRJl5yCAgAftj0xikfKE1XCZP/bVRZd8Glf+pmNn0qexmwEJlp3psLUGxeHL4iL\r\nXDATMO7BZEIFxjE4g5OLLY5GfN3ALIX3ADzRAgMBAAGgADANBgkqhkiG9w0BAQsF\r\nAAOCAQEALuIaqSVUQEOAaEPhXXwcTF8RBuR78WqXZ0dCLHEv/86HnsgH1kee03RF\r\n4LoJb1W5o3LxE5+wjN4oRxMor7o2SUaVkE8ITS5esxGp6umoLLACcbFILwKupUBY\r\nj4lP/YjlhYdBQ0jXu6/mwhOkNZVlv0pHwezn1At7JbVfvmOOPT5EsvosKU4QEBll\r\nYh0StqgWEE0IAJJGgFKbQh1c8a87oVZVc1y0rR+33jlvOa4/K3PhPlRIfzX757k+\r\nYameUjRDQZMSVtmLzRpHYErfKx9qt/ayZHHPJV76D4JjHbLbxOmV5fOwJ0gYhxMC\r\noRo5bDf7gG96ukZ3WIJluky7ZFlzFA==\r\n-----END CERTIFICATE REQUEST-----\r\n", "server_software_id"=>"1", "agreement"=>"1", "id"=>"75900"}}},
          "add_to_manager"=>"true", "managed_csr"=>"none", "common_name"=>"106.255.212.123", "old_common_name"=>"", "x"=>"79", "y"=>"25", "id"=>"#{co.ref}"}

      put :update_csr, params
      assert_template :submit_csr
      # assert_equal 'Article was successfully created.', flash[:notice]
    end
  end

  it 'allows a user to download certificate orders in csv format' do
    certificate = create(:certificate_with_certificate_order)
    co = build(:certificate_order)
    co.sub_order_items << certificate.product_variant_items.first.sub_order_item
    co.ssl_account.users << @user
    co.certificate_contents << build(:certificate_content)
    co.save

    post :download_certificates, co_ids: co.id, format: :csv
    response.code.must_equal "200"
    response.body.must_match "Order Ref,Order Label,Duration,Signed Certificate,Status,Effective Date,Expiration Date"
  end
end
