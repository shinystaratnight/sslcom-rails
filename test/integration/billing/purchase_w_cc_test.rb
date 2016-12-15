require 'test_helper'

describe 'User Logged In: valid cc' do
  before do
    initialize_roles
    create(:certificate, :basicssl)
    @invited_user_email = 'invited_user@domain.com'
    @current_admin      = create(:user, :account_admin)
    @invited_user       = create(:user, :account_admin, email: @invited_user_email)
    @invited_ssl_acct   = @current_admin.ssl_account
    @invited_user_ssl   = @invited_user.ssl_account
    approve_user_for_account(@invited_ssl_acct, @invited_user)
    @invited_ssl_acct.billing_profiles << create(:billing_profile)
    @year_3_id          = ProductVariantItem.find_by(serial: "sslcombasic256ssl3yr").id

    login_as(@current_admin, self.controller.cookies)
  end

  focus
  it 'basicssl' do
    visit buy_certificate_path 'basicssl'
    # Subscriber Agreement
    find('#certificate_order_certificate_contents_attributes_0_agreement').click
    find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.14/yr
    page.must_have_content('$156.43 USD') # $52.14 * 3 years
    
    # Shopping Cart
    find('#next_submit input').click
    page.must_have_content('$156.43 USD')
    
    # Checkout
    click_on 'Checkout'
    page.must_have_content('Funding Sources')
    page.must_have_content(@invited_ssl_acct.billing_profiles.first.last_digits)
    page.must_have_content('Order Amount: charged in $USD $156.43 USD')
    find("#funding_source_#{BillingProfile.first.id}").click
    
    find('input[name="next"]').click
    screenshot_and_save_page
  end
end
