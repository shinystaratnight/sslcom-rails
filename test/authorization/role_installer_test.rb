require 'test_helper'

describe 'installer role' do
  before do
    prepare_auth_tables
    @owner       = create(:user, :owner)
    @owner_ssl   = @owner.ssl_account
    @installer   = create_and_approve_user(@owner_ssl, 'installer_login', @installer_role)
    
    2.times {login_as(@installer, self.controller.cookies)}
    visit switch_default_ssl_account_user_path(@installer.id, ssl_account_id: @owner_ssl.id)
    @installer = User.find_by(login: 'installer_login')
  end

  describe 'tabs/index pages' do
    it 'SHOULD permit' do
      # certificate_orders index (Order tab)
      should_permit_path certificate_orders_path
      # validations index (Validations tab)
      should_permit_path validations_path
      # teams index (Teams tab)
      should_permit_path teams_user_path(@installer)
      # site_seals index (Site Seals tab)
      should_permit_path site_seals_path
      # users/show (Dashboard tab)
      should_permit_path user_path(@installer)
    end

    it 'SHOULD NOT permit' do
      # orders index (Transactions tab)
      should_not_permit_path orders_path
      # users index (Users tab)
      should_not_permit_path users_path
      # billing_profiles index (Billing Profiles tab)
      should_not_permit_path billing_profiles_path
    end
  end
  
  describe 'page and header' do
    it 'SHOULD see' do
      # certificate order header items
      should_see_cert_order_headers @installer
      # 'api credentials' link
      should_see_api_credentials @installer
    end

    it 'SHOULD NOT see' do
      # CART ITEMS header item
      should_not_see_cart_items @installer
      # AVAILABLE FUNDS header item
      should_not_see_available_funds @installer
      # 'buy certificate' link
      should_not_see_buy_certificate @installer
    end
  end

  describe 'certificate orders' do
    before do
      login_as(@owner, self.controller.cookies)
      prepare_certificate_orders @owner
      co_state_issued
      login_as(@installer, self.controller.cookies)
    end

    it 'SHOULD see' do
      # certificate download table
      visit certificate_orders_path
      should_see_cert_download_table
      
      # 'Reprocess' and 'Renew' links
      should_see_reprocess_link
      co_state_renewal
      should_see_renew_link

      # site seal JS code
      visit certificate_orders_path
      click_on 'seal'
      should_see_site_seal_js
    end
  end
end
