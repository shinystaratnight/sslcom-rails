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
  end

  it 'allows a user to download certificate orders in csv format' do
    login_as(@user)
    certificate = create(:certificate_with_certificate_order)
    co = build(:certificate_order)
    co.sub_order_items << certificate.product_variant_items.first.sub_order_item
    co.ssl_account.users << @user
    co.certificate_contents << build(:certificate_content)
    co.save

    post :download_certificates, co_ids: co.id, format: :csv
    response.code.must_equal "200"
    response.body.must_match "Order Ref,Name,Status,Order Date,Expiration Date"
  end
end
