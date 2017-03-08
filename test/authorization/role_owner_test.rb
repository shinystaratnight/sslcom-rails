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

    it 'SHOULD NOT permit' do
      # leave team they own
      should_not_permit_path leave_team_user_path(@owner, ssl_account_id: @owner_ssl.id)
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
    before do 
      visit users_path
      @total_users = @owner_ssl.users.count
    end

    it 'SHOULD see' do
      page.all(:css, '.dropdown').each {|expand| expand.click} # expand all users
      page.must_have_content('change roles', count: 6)
      page.must_have_content('remove user from this account', count: 6)
      page.must_have_content('enabled?', count: 6)
      page.must_have_content('disabled', count: 6)
    end

    it 'SHOULD permit' do
      # edit user
      should_permit_path edit_managed_user_path(@ssl_slug, @account_admin.id)
      should_permit_path edit_managed_user_path(@ssl_slug, @billing.id)
      should_permit_path edit_managed_user_path(@ssl_slug, @users_manager.id)
      should_permit_path edit_managed_user_path(@ssl_slug, @validations.id)
      should_permit_path edit_managed_user_path(@ssl_slug, @installer.id)

      # remove from team
      visit remove_from_account_managed_user_path(@owner_ssl, @account_admin2.id)
      assert_equal @total_users - 1, @owner_ssl.users.count
      visit remove_from_account_managed_user_path(@owner_ssl, @billing.id)
      assert_equal @total_users - 2, @owner_ssl.users.count
      visit remove_from_account_managed_user_path(@owner_ssl, @users_manager.id)
      assert_equal @total_users - 3, @owner_ssl.users.count
      visit remove_from_account_managed_user_path(@owner_ssl, @validations.id)
      assert_equal @total_users - 4, @owner_ssl.users.count
      visit remove_from_account_managed_user_path(@owner_ssl, @installer.id)
      assert_equal @total_users - 5, @owner_ssl.users.count
    end

    it 'SHOULD NOT permit' do
      # edit self
      should_not_permit_path edit_managed_user_path(@ssl_slug, @owner.id)
      # remove SELF from team
      should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @owner.id)
    end
  end
end