require 'test_helper'

describe 'owner role' do
  before do
    prepare_auth_tables
    @owner     = create(:user, :owner)
    @owner_ssl = @owner.ssl_account
    @billing   = create_and_approve_user(@owner_ssl, 'billing_login', @billing_role)
    
    2.times {login_as(@billing, self.controller.cookies)}
    visit switch_default_ssl_account_user_path(@billing.id, ssl_account_id: @owner_ssl.id)
    @billing = User.find_by(login: 'billing_login')
  end

  describe 'tabs/index pages' do
    it 'SHOULD permit' do
      # certificate_orders index (Order tab)
      should_permit_path certificate_orders_path
      # orders index (Transactions tab)
      should_permit_path orders_path
      # users/show (Dashboard tab)
      should_permit_path user_path(@owner)
      # billing_profiles index (Billing Profiles tab)
      should_permit_path billing_profiles_path
      # teams index (Teams tab)
      should_permit_path teams_user_path(@owner)
    end

    it 'SHOULD NOT permit' do
      # validations index (Validations tab)
      should_not_permit_path validations_path
      # site_seals index (Site Seals tab)
      should_not_permit_path site_seals_path
      # users index (Users tab)
      should_not_permit_path users_path
    end
  end
  
  describe 'page and header' do
    it 'SHOULD see' do
      # CART ITEMS header item
      should_see_cart_items @billing
      # AVAILABLE FUNDS header item
      should_see_available_funds @billing
      # 'buy certificate' link
      should_see_buy_certificate @billing
      
    end
    it 'SHOULD NOT see' do
      # 'api credentials' link
      should_not_see_api_credentials @billing
      # certificate order header items
      should_not_see_cert_order_headers @billing
    end
  end

  # TODO: Implement view for billing user.
  # describe 'certificate orders' do
  #   before do
  #     prepare_certificate_orders @billing
  #     co_state_issued
  #   end

  #   it 'SHOULD see' do
  #     # 'Renew' links
  #     co_state_renewal
  #     should_see_renew_link
  #   end

  #   it 'SHOULD NOT see' do
  #     # certificate download table
  #     visit certificate_orders_path
  #     should_not_see_cert_download_table

  #     #'change domain(s)/rekey' links
  #     should_not_see_reprocess_link

  #     # site seal JS code
  #   end
  # end
end
