module ApiSetupHelper
  def api_main_setup
      Authorization.ignore_access_control(true)
      initialize_roles
      initialize_server_software
      initialize_certificates
      initialize_certificate_csr_keys
      initialize_countries
      @card_number  = BillingProfile.gateway_stripe? ? '4242424242424242' : '4007000000027'
      @user         = create(:user, :owner)
      @team         = @user.ssl_account
      @api_keys     = {
        account_key: @team.api_credential.account_key,
        secret_key:  @team.api_credential.secret_key
      }
  end
  
  # Basic request to buy a certificate, voucher/ref number is returned if successful
  # product:
  #    100 (for EV UCC SSL)
  #    101 (for UCC SSL)
  #    103 (for High Assurance SSL)
  #    102 (for EV SSL)
  #    104 (for Free SSL)
  #    105 (for Wildcard SSL)
  #    106 (for Basic SSL)
  #    107 (for Premium SSL)
  # period:
  #    365 or 730 for EV SSL certs
  #    30 or 90 for Free Trial SSL certs
  #    365, 730, 1095, 1461, or 1826 for all others
  def api_get_request_for_voucher
    @api_keys.merge(api_get_basic_ssl)
  end
  
  def api_get_basic_ssl
    {product: 106, period: 365}
  end

  # Certificate content registrant
  def api_get_csr_registrant
    {
      organization_name:      'SSL.com Org',    # company_name
      organization_unit_name: 'IT Department',  # department
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
  
  # Required only if csr is specified, otherwise contacts will be ignored.
  def api_get_csr_contacts
    {
      contacts: {
        all: {                # all: administrative, billing, technical, validation
          first_name:         'first_name',           # required
          last_name:          'last_name',            # required
          email:              'csr_test@domain.com',  # required
          phone:              '9161223444',           # required
          address1:           '123 H St.',
          address2:           nil,
          address3:           nil,
          po_box:             nil,
          city:               'Houston',
          postal_code:        '77098',
          organization:       'SSL Org',
          country:            'US'                    # Applicant country code (ISO3166 2-character country code)
        }
      }
    }
  end
  
  def api_get_server_software
    {server_software: 3}
  end
  
  def api_get_nonwildcard_csr_hash
    {csr: @nonwildcard_csr}
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
  # csr is specified
  #   dcv: The domain control validation method to be performed for a given domain.
  #   valid values for the dcv are:
  #     HTTP_CSR_HASH
  #     HTTPS_CSR_HASH
  #     CNAME_CSR_HASH
  def api_get_domains_with_csr
    {
      domains: {
        'mail.ssltestdomain1.com': {dcv: 'HTTP_CSR_HASH'},
        'www.ssltestdomain2.com':  {dcv: 'admin@ssltestdomain2.com'}
      }
    }
  end
end