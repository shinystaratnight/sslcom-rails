require 'test_helper'

describe 'users_manager role' do
  before do
    prepare_auth_tables
    @owner       = create(:user, :owner)
    @owner_ssl   = @owner.ssl_account
    @users_manager   = create_and_approve_user(@owner_ssl, 'users_manager_login', @users_manager_role)
    
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
      # owner's edit password page
      should_not_permit_path edit_password_user_path(@owner)
      # owner's edit email page
      should_not_permit_path edit_email_user_path(@owner)
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
end
