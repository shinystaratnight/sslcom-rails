module ApiSetupHelper
  def api_main_setup
      Authorization.ignore_access_control(true)
      initialize_roles
      initialize_server_software
      initialize_certificates
      initialize_certificate_csr_keys
      initialize_countries
      api_initialize_pvi_ids
      @card_number  = api_set_card_number
      @user         = create(:user, :owner)
      @team         = @user.ssl_account
      @api_keys     = {
        account_key: @team.api_credential.account_key,
        secret_key:  @team.api_credential.secret_key
      }
      set_api_host
  end

  def api_min_setup
    Authorization.ignore_access_control(true)
    initialize_roles
    @card_number  = api_set_card_number
    @user         = create(:user, :owner)
    @team         = @user.ssl_account
    @api_keys     = {
      account_key: @team.api_credential.account_key,
      secret_key:  @team.api_credential.secret_key
    }
    set_api_host
  end
  
  def api_set_card_number
    BillingProfile.gateway_stripe? ? '4242424242424242' : '4007000000027'
  end
  
  def set_api_host
    api_host = "sws.sslpki.local"
    host! api_host
    Capybara.app_host = "http://www." + api_host
  end

  # ProductVariantItem ids
  def api_initialize_pvi_ids
    @ev_ucc_to3_domains   = ProductVariantItem.find_by_serial('sslcomevucc256ssl1yrdm').id
    @ev_ucc_over3_domains = ProductVariantItem.find_by_serial('sslcomevucc256ssl1yradm').id
    @ucc_min_domains      = ProductVariantItem.find_by_serial('sslcomucc256ssl1yrdm').id
    @ucc_max_domains      = ProductVariantItem.find_by_serial('sslcomucc256ssl1yradm').id
    @ucc_server_license   = ProductVariantItem.find_by_serial('sslcomucc256ssl1yrsl').id
    @ucc_wildcard         = ProductVariantItem.find_by_serial('sslcomucc256ssl1yrwcdm').id
    @basic_domains        = ProductVariantItem.find_by_serial('sslcombasic256ssl1yr').id
  end
  
  # SubOrderItem quantaties for specific product_variant_item_id
  def api_get_sub_order_quantaty(pvi_id)
    SubOrderItem.where(product_variant_item_id: pvi_id).first.quantity
  end
    
  # SSL Certificates
  #  product:
  #    100 (for EV UCC SSL)
  #    101 (for UCC SSL)
  #    103 (for High Assurance SSL)
  #    102 (for EV SSL)
  #    104 (for Free SSL)
  #    105 (for Wildcard SSL)
  #    106 (for Basic SSL)
  #    107 (for Premium SSL)
  #  period:
  #    365 or 730 for EV SSL certs
  #    30 or 90 for Free Trial SSL certs
  #    365, 730, 1095, 1461, or 1826 for all others
  
  # EV UCC SSL (evucc256sslcom)
  def api_get_request_for_evucc
    @api_keys.merge(product: 100, period: 365)
  end
  
  # UCC SSL (ucc256sslcom)
  def api_get_request_for_ucc
    @api_keys.merge(product: 101, period: 365)
  end
  
  # EV SSL (ev256sslcom)
  def api_get_request_for_ev
    @api_keys.merge(product: 102, period: 365)
  end
  
  # High Assurance SSL (ov256sslcom)
  def api_get_request_for_ov
    @api_keys.merge(product: 103, period: 365)
  end
  
  # Free SSL 
  def api_get_request_for_free
    @api_keys.merge(product: 104, period: 90)
  end
  
  # Wildcard SSL (wc256sslcom)
  def api_get_request_for_wildcard
    @api_keys.merge(product: 105, period: 365)
  end
  
  # Basic SSL (basic256sslcom)
  def api_get_request_for_dv
    @api_keys.merge(product: 106, period: 365)
  end
  
  # Premium SSL (premium256sslcom)
  def api_get_request_for_premium
    @api_keys.merge(product: 107, period: 365)
  end
  
  def api_get_new_billing_info
    {
      first_name:       'cc_first_name',
      last_name:        'cc_last_name',
      credit_card:      'Visa',
      card_number:      @card_number,
      expiration_year:  Date.today.year+5,
      expiration_month: 1,
      security_code:    900,
      address_1:        '123 H St.',
      address_2:        'Suite A',
      city:             'Houston',
      state:            'Texas',
      postal_code:      12345,
      country:          'US',
      phone:            '9161223444'
    }
  end

  # Certificate content registrant
  def api_get_csr_registrant
    {
      organization:      'SSL.com Org',         # company_name
      organization_unit: 'IT Department',       # department
      street_address_1:       '123 H St.',      # address1
      street_address_2:       nil,              # address2
      street_address_3:       nil,              # address3
      post_office_box:        nil,              # po_box
      locality_name:          'Houston',        # city
      state_or_province_name: 'Texas',          # state
      postal_code:            '77777',
      country:                'US'
    }
  end

  def api_get_registrant
    {
      company_name: 'ABC Company',          # required IF organization
      first_name:   'first_name',           # required IF individual
      last_name:    'last_name',            # required IF individual
      email:        'csr_test@domain.com',  # required
      phone:        '9161223444',           # required
      address1:     '123 H St.',            # required
      address2:     nil,
      address3:     nil,
      po_box:       nil,
      city:         'Houston',              # required
      state:        'TX',                   # required
      postal_code:  '77098',                # required
      organization: 'SSL Org',
      country:      'US',                   # required: country code (ISO3166 2-character country code)
      registrant_type: Registrant::registrant_types[:organization]
    }
  end
  
  def api_get_contact
    {
      first_name:   'first_name',           # required
      last_name:    'last_name',            # required
      email:        'example@domain.com',   # required
      phone:        '9161223444',           # required
      address1:     '123 H St.',            # required
      address2:     nil,
      address3:     nil,
      po_box:       nil,
      city:         'Houston',              # required
      state:        'TX',                   # required
      postal_code:  '77098',                # required
      country:      'US',                   # required: Country code (ISO3166 2-character country code)
      organization: 'SSL Org',
      organization_unit: 'Software Department'
    }
  end
  
  def api_create_contact
    {
      first_name:   'first_name',           # required
      last_name:    'last_name',            # required
      company_name: 'SSL Org',
      department:   'Software Department',
      email:        'example@domain.com',   # required
      phone:        '9161223444',           # required
      address1:     '123 H St.',            # required
      address2:     nil,
      address3:     nil,
      po_box:       nil,
      city:         'Houston',              # required
      state:        'TX',                   # required
      postal_code:  '77098',                # required
      organization: 'SSL Org',
      country:      'US',                    # required: Country code (ISO3166 2-character country code)
      roles:        ['administrative']
    }
  end
  
  # Required only if csr is specified, otherwise contacts will be ignored.
  def api_get_csr_contacts
    {
      contacts: {
        all: api_get_contact # all: administrative, billing, technical, validation
      }
    }
  end
  
  def api_get_server_software
    {server_software: 3}
  end
  
  def api_get_nonwildcard_csr_hash
    {csr: @nonwildcard_csr}
  end
  
  def api_get_wildcard_csr_hash
    {csr: @wildcard_csr}
  end
  
  # Applicant Representative used for callback. Only for OV certificates
  def api_get_app_rep
    {
      first_name:        'app_rep_first',
      last_name:         'app_rep_last',
      email_address:     '',
      phone_number:      '9161231234',
      title:             'owner',
      fax:               nil,
      organization:      'SSL Org',
      organization_unit: 'IT Department',
      street_address_1:  '123 H St.',
      street_address_2:  nil,
      street_address_3:  nil,
      post_office_box:   nil,
      locality:          'Houston',
      state_or_province: 'Texas',
      postal_code:       '77098',
      country:           'US',
    }
  end
  
  # Optional: payment
  # If payment method is specified, then payment will override the
  # default method of deducting funds from the prepaid deposit/funded account.
  def api_get_payment_method
    {
      payment: {
        credit_card: {
          first_name:        'cc_first',
          last_name:         'cc_last',
          number:            @card_number,
          expires:           "01#{(Date.today + 2.years).strftime('%y')}", #mmyy
          cvv:               900,
          street_address_1:  nil,
          street_address_2:  nil,
          street_address_3:  nil,
          post_office_box:   nil,
          locality:          nil,
          state_or_province: nil,
          postal_code:      '77098',
          country:          'US'
        }
      }
    }
  end
  
  # Optional: domains
  # Domains to be included in the certificate. These values override those listed in the csr. 
  # If domains is not specified, the domains for the certificate order will be 
  # extracted from the certificate signing request (csr). If you want to use 
  # some or all of the domains encoded in the csr along with some additional 
  # domains, then you must list all domains in this parameter. 
  # The first domain listed in the hash is by default listed in the CN field 
  # and the other domains will be listed in the SAN field. 
  # Multiple domains can only be listed for the following products: 100, 102, 107. 
  # Other product types will only use the first domain and ignore the other domains.
  def api_get_domains_no_csr
    { domains: ['www.ssltestdomain1.com', 'www.ssltestdomain2.com'] }
  end
  # for multi domain ucc ssl; csr is specified
  #   dcv: The domain control validation method to be performed for a given domain.
  #   valid values for the dcv are:
  #     HTTP_CSR_HASH
  #     HTTPS_CSR_HASH
  #     CNAME_CSR_HASH
  def api_get_domains_for_csr
    {
      domains: {
        'mail.ssltestdomain1.com': {dcv: 'HTTP_CSR_HASH'},
        'www.ssltestdomain2.com':  {dcv: 'admin@ssltestdomain2.com'}
      }
    }
  end
  
  # for single domain ssl; csr is specified
  #   dcv: The domain control validation method to be performed for a given domain.
  #   valid values for the dcv are:
  #     HTTP_CSR_HASH
  #     HTTPS_CSR_HASH
  #     CNAME_CSR_HASH
  def api_get_domain_for_csr
    {
      domains: {
        'mail.ssltestdomain1.com': {dcv: 'HTTP_CSR_HASH'},
      }
    }
  end

  def api_get_wildcard_domains_for_csr
    {
      domains: {
        '*.ssltestdomain1.com': {dcv: 'HTTP_CSR_HASH'},
        '*.ssltestdomain2.com': {dcv: 'HTTP_CSR_HASH'}
      }
    }
  end
  
  # Validate CaApiRequest when CSR hash is provided
  # Two total: 1. SSL API create endpoint 
  #            2. Comodo API AutoApplySSL endpoint
  def api_ca_api_requests_when_csr
    ca_request_1 = CaApiRequest.find_by_api_requestable_type 'SslAccount'
    ca_request_2 = CaApiRequest.find_by_api_requestable_type 'Csr'

    # request to SSL.com API certificate create action
    assert_match 'ssl.com', ca_request_1.ca
    assert_match 'ApiCertificateCreate_v1_4', ca_request_1.type
    # request to comodo w/successful response
    assert_match 'comodo', ca_request_2.ca
    assert_includes ca_request_2.response, 'errorCode=0'
    assert_includes ca_request_2.response, 'orderNumber='
    assert_match 'CaCertificateRequest', ca_request_2.type
    assert_match 'https://secure.trust-provider.com/products/!AutoApplySSL', ca_request_2.request_url
  end
  
  def api_assert_non_wildcard_csr
    csr = Csr.first
    assert_equal 1, Csr.count
    assert_match 'qlikdev.ezops.com', csr.common_name
    assert_match 'EZOPS Inc', csr.organization
    assert_match 'IT', csr.organization_unit
    assert_match 'vishal@ezops.com', csr.email
    assert_match 'sha256WithRSAEncryption', csr.sig_alg
    refute_nil   csr.body
  end
  
  def api_assert_wildcard_csr
    csr = Csr.first
    assert_equal 1, Csr.count
    assert_equal 2048, csr.strength
    assert_match '*.rubricae.es', csr.common_name
    assert_match 'Promoland Media S.L.', csr.organization
    assert_match 'Comunicaciones', csr.organization_unit
    assert_match 'soporte@promoland.es', csr.email
    assert_match 'sha256WithRSAEncryption', csr.sig_alg
    refute_nil   csr.body
  end
end