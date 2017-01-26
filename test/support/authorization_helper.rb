module AuthorizationHelper
  def prepare_auth_tables
    create_reminder_triggers
    create_roles
    initialize_certificates
  end

  def should_permit_path(path)
    visit path
    assert_match path, current_path
  end

  def should_see_cart_items(user)
    visit user_path user
    page.must_have_content 'CART ITEMS'
  end

  def should_not_see_cart_items(user)
    visit user_path user
    page.should_not_have_content 'CART ITEMS'
  end

  def should_see_available_funds(user)
    visit user_path user
    page.must_have_content 'AVAILABLE FUNDS'        # header section
    page.must_have_content 'available funds: $0.00' # dashboard summary
  end

  def should_see_buy_certificate(user)
    visit user_path user
    page.must_have_content 'buy certificate'
  end

  def should_see_api_credentials(user)
    visit user_path user
    page.must_have_content 'api credentials'
    page.must_have_content 'account key'
    page.must_have_content 'secret key'
  end

  def should_see_cert_order_headers(user)
    visit user_path user 
    if user.is_system_admins?
      page.must_have_content('IN PROGRESS')
      page.must_have_content('REPROCESSING')
      page.must_have_content('NEED MORE INFO')
    else
      page.must_have_content('INCOMPLETE')
      page.must_have_content('PROCESSING')
    end
  end
  # 
  # Generates a certificate order and all associated records for the passed in 
  # user's ssl_account. Used for validaing user authorization for all roles.
  # 
  def prepare_certificate_orders(user)
    initialize_server_software
    initialize_certificate_csr_keys

    @logged_in_ssl_acct = user.ssl_account
    @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
    @year_3_id          = ProductVariantItem.find_by(serial:  "sslcombasic256ssl3yr").id
    # Purchase basic non-wildcard certificate
    # =========================================================
    visit buy_certificate_path 'basicssl'
    find('#certificate_order_certificate_contents_attributes_0_agreement').click
    find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.14/yr
    find('#next_submit input').click # Shopping Cart
    click_on 'Checkout'              # Checkout
    find("#funding_source_#{BillingProfile.first.id}").click
    find('input[name="next"]').click
    # Submit and validate CSR Key for non-wilrdcard certificate
    # =========================================================
    visit certificate_orders_path   # Certificate Orders
    # Step 1: Submit CSR
    click_on 'submit csr'
    main_id = 'certificate_order_certificate_contents_attributes_0'
    fill_in "#{main_id}_signing_request", with: @nonwildcard_csr.strip
    select  'Oracle',                     from: "#{main_id}_server_software_id"
    find('#next_submit').click
    # Step 2: Registrant
    registrant_id = 'certificate_order_certificate_contents_attributes_0_registrant_attributes'
    fill_in "#{registrant_id}_company_name", with: 'EZOPS Inc'
    fill_in "#{registrant_id}_address1",     with: '123 H St.'
    fill_in "#{registrant_id}_city",         with: 'Houston'
    fill_in "#{registrant_id}_state",        with: 'TX'
    fill_in "#{registrant_id}_postal_code",  with: '12345'
    find('input[alt="edit ssl certificate order"]').click
    # Step 3: Contacts
    contacts_id = 'certificate_content_certificate_contacts_attributes_0'
    fill_in "#{contacts_id}_first_name", with: 'first'
    fill_in "#{contacts_id}_last_name",  with: 'last'
    fill_in "#{contacts_id}_email",      with: 'test_contact@domain.com'
    fill_in "#{contacts_id}_phone",      with: '1233334444'
    find('input[alt="Bl submit button"]').click
  end
end
