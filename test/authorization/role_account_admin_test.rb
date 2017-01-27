require 'test_helper'

describe 'owner role' do
  before do
    prepare_auth_tables
    @owner         = create(:user, :owner)
    @owner_ssl     = @owner.ssl_account
    @account_admin = create_and_approve_user(@owner_ssl, 'account_admin_login')
    
    2.times {login_as(@account_admin, self.controller.cookies)}
    find('div.acc-sel-dropbtn').click                    # CURRENT TEAM dropdown
    find('a', text: @owner_ssl.acct_number.upcase).click # switch to @owner's team
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
      should_permit_path billing_profiles_path
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
end
