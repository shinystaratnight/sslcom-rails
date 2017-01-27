require 'test_helper'

describe 'owner role' do
  before do
    prepare_auth_tables
    @owner = create(:user, :owner)
    login_as(@owner, self.controller.cookies)
  end

  describe 'tabs/index pages' do
    it 'CAN certificate_orders index (Order tab)' do
      should_permit_path certificate_orders_path
    end

    it 'CAN orders index (Transactions tab)' do
      should_permit_path orders_path
    end  

    it 'CAN validations index (Validations tab)' do
      should_permit_path validations_path
    end

    it 'CAN teams index (Teams tab)' do
      should_permit_path teams_user_path(@owner)
    end

    it 'CAN site_seals index (Site Seals tab)' do
      should_permit_path site_seals_path
    end

    it 'CAN users index (Users tab)' do
      should_permit_path users_path
    end

    it 'CAN users/show (Dashboard tab)' do
      should_permit_path user_path(@owner)
    end

    it 'CAN billing_profiles index (Billing Profiles tab)' do
      should_permit_path billing_profiles_path
    end
  end
  
  describe 'page and header' do
    it 'CAN see certificate order header items' do
      should_see_cert_order_headers @owner
    end
    
    it 'CAN see CART ITEMS header item' do
      should_see_cart_items @owner
    end

    it 'CAN see AVAILABLE FUNDS header item' do
      should_see_available_funds @owner
    end

    it "CAN see 'buy certificate' link" do
      should_see_buy_certificate @owner
    end

    it "CAN see 'api credentials' link" do
      should_see_api_credentials @owner
    end
  end

  describe 'certificate orders' do
    before do
      prepare_certificate_orders @owner
      co_state_issued
    end
    
    # it 'CAN see certificate download table' do
        
    # end
    
    it "CAN see 'Reprocess' and 'Renew' links" do
      should_see_reprocess_link
      co_state_renewal
      should_see_renew_link
    end
  end

  describe 'site seals' do
    before do
      prepare_certificate_orders @owner
      co_state_issued
      visit certificate_orders_path
    end

    it 'CAN see site seal JS code' do
      click_on 'seal'
      should_see_site_seal_js
    end
  end
end
