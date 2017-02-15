require 'test_helper'

describe 'users_manager role' do
  before do
    prepare_auth_tables
    @users_manager2  = create_and_approve_user(@owner_ssl, 'users_manager_login2', @users_manager_role)
    2.times {login_as(@users_manager, self.controller.cookies)}
    visit switch_default_ssl_account_user_path(@users_manager.id, ssl_account_id: @owner_ssl.id)
    @users_manager = User.find_by(login: 'users_manager_login')
  end

  describe 'tabs/index pages' do
    it 'SHOULD permit' do
      # teams index (Teams tab)
      should_permit_path teams_user_path(@users_manager)
      # users index (Users tab)
      should_permit_path users_path
      # users/show (Dashboard tab)
      should_permit_path user_path(@users_manager)
    end

    it 'SHOULD NOT permit' do
      # certificate_orders index (Order tab)
      should_not_permit_path certificate_orders_path
      # validations index (Validations tab)
      should_not_permit_path validations_path
      # site_seals index (Site Seals tab)
      should_not_permit_path site_seals_path
      # orders index (Transactions tab)
      should_not_permit_path orders_path
      # billing_profiles index (Billing Profiles tab)
      should_not_permit_path billing_profiles_path(@owner_ssl.to_slug)
    end
  end
  
  describe 'page and header' do
    it 'SHOULD see' do
      # 'api credentials' link
      should_see_api_credentials @users_manager
    end

    it 'SHOULD NOT see' do
      # certificate order header items
      should_not_see_cert_order_headers @users_manager
      # CART ITEMS header item
      should_not_see_cart_items @users_manager
      # AVAILABLE FUNDS header item
      should_not_see_available_funds @users_manager
      # 'buy certificate' link
      should_not_see_buy_certificate @users_manager
    end
  end

  describe 'users' do
    before do 
      visit users_path
      @ssl_slug = @owner_ssl.to_slug
    end

    it 'SHOULD see' do
      page.all(:css, '.dropdown').each {|expand| expand.click} # expand all users
      # cannot manage: self, :owner, :account_admin
      #    can manage: :installer, :billing, :validations, other :users_manager
      assert_equal 8, SslAccountUser.where(ssl_account_id: @owner_ssl.id).map(&:user).count
      page.must_have_content('change roles', count: 4)
      page.must_have_content('remove user from this account', count: 4)
    end

    it 'SHOULD permit' do
      # edit billing role
      should_permit_path edit_managed_user_path(@ssl_slug, @billing.id)
      # edit other users_manager role
      should_permit_path edit_managed_user_path(@ssl_slug, @users_manager2.id)
      # edit validations role
      should_permit_path edit_managed_user_path(@ssl_slug, @validations.id)
      # edit installer role
      should_permit_path edit_managed_user_path(@ssl_slug, @installer.id)
    end

    it 'SHOULD NOT permit' do
      # edit self
      should_not_permit_path edit_managed_user_path(@ssl_slug, @users_manager.id)
      # edit owner role
      should_not_permit_path edit_managed_user_path(@ssl_slug, @owner.id)
      # edit account_admin role
      should_not_permit_path edit_managed_user_path(@ssl_slug, @account_admin.id)
    end
  end  
end
