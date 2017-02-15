require 'test_helper'

describe 'owner role' do
  before do
    prepare_auth_tables
    login_as(@owner, self.controller.cookies)
  end

  describe 'tabs/index pages' do
    it 'SHOULD permit' do
      # certificate_orders index (Order tab)
      should_permit_path certificate_orders_path
      # orders index (Transactions tab) 
      should_permit_path orders_path 
      # validations index (Validations tab)
      should_permit_path validations_path
      # teams index (Teams tab)
      should_permit_path teams_user_path(@owner)
      # site_seals index (Site Seals tab)
      should_permit_path site_seals_path
      # users index (Users tab)
      should_permit_path users_path
      # users/show (Dashboard tab)
      should_permit_path user_path(@owner)
      # billing_profiles index (Billing Profiles tab)
      should_permit_path billing_profiles_path(@owner.ssl_account.to_slug)
    end
  end
  
  describe 'page and header' do
    it 'SHOULD see' do
      # certificate order header items
      should_see_cert_order_headers @owner
      # CART ITEMS header item
      should_see_cart_items @owner
      # AVAILABLE FUNDS header item
      should_see_available_funds @owner
      # 'buy certificate' link
      should_see_buy_certificate @owner
      # 'api credentials' link
      should_see_api_credentials @owner
    end
  end

  describe 'certificate orders' do
    before do
      prepare_certificate_orders @owner
      co_state_issued
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

  describe 'users' do
    before {visit users_path}

    it 'SHOULD see' do
      page.all(:css, '.dropdown').each {|expand| expand.click} # expand all users
      page.must_have_content('change roles', count: 6)
      page.must_have_content('remove user from this account', count: 6)
      page.must_have_content('enabled', count: 6)
      page.must_have_content('disabled', count: 6)
    end

    it 'SHOULD permit' do
      # edit other account_admin role
      should_permit_path edit_managed_user_path(@ssl_slug, @account_admin.id)
      # edit billing role
      should_permit_path edit_managed_user_path(@ssl_slug, @billing.id)
      # edit users_manager role
      should_permit_path edit_managed_user_path(@ssl_slug, @users_manager.id)
      # edit validations role
      should_permit_path edit_managed_user_path(@ssl_slug, @validations.id)
      # edit installer role
      should_permit_path edit_managed_user_path(@ssl_slug, @installer.id)
    end

    it 'SHOULD NOT permit' do
      # edit self
      should_not_permit_path edit_managed_user_path(@ssl_slug, @owner.id)
    end
  end
end
