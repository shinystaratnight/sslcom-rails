require 'test_helper'

describe 'validations role' do
  before do
    prepare_auth_tables
    @owner       = create(:user, :owner)
    @owner_ssl   = @owner.ssl_account
    @validations = create_and_approve_user(@owner_ssl, 'validation_login', @validations_role)
    
    2.times {login_as(@validations, self.controller.cookies)}
    visit switch_default_ssl_account_user_path(@validations.id, ssl_account_id: @owner_ssl.id)
    @validations = User.find_by(login: 'validation_login')
  end

  describe 'tabs/index pages' do
    it 'SHOULD permit' do
      # users/show (Dashboard tab)
      should_permit_path user_path(@validations)
      # validations index (Validations tab)
      should_permit_path validations_path
      # teams index (Teams tab)
      should_permit_path teams_user_path(@validations)
      # site_seals index (Site Seals tab)
      should_permit_path site_seals_path
    end

    it 'SHOULD NOT permit' do
      # certificate_orders index (Order tab)
      should_not_permit_path certificate_orders_path
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
      should_see_cert_order_headers @validations
    end

    it 'SHOULD NOT see' do
      # CART ITEMS header item
      should_not_see_cart_items @validations
      # AVAILABLE FUNDS header item
      should_not_see_available_funds @validations
      # 'buy certificate' link
      should_not_see_buy_certificate @validations
      # 'api credentials' link
      should_not_see_api_credentials @validations
    end
  end

  describe 'site seals' do
    before do
      login_as(@owner, self.controller.cookies)
      prepare_certificate_orders @validations
      co_state_issued
      login_as(@validations, self.controller.cookies)
    end

    it 'SHOULD NOT see' do
      visit certificate_order_site_seal_path(
        @validations.ssl_account.to_slug, CertificateOrder.first.ref
      )
      # site seal JS code
      should_not_see_site_seal_js
    end
  end
end
