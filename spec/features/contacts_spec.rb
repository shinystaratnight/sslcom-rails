require 'rails_helper'

RSpec.describe 'Contacts', type: :feature do
  include AuthenticationHelpers

  let!(:user) { create(:user, :owner) }

  it 'can add an administrative contact', js: true do
    Authorization::Maintenance.without_access_control do
      user.create_ssl_account if user.ssl_account.nil?
      user.ssl_accounts.first.generate_funded_account
      user.ssl_accounts.first.funded_account.update(cents: 100_000)
    end

    login_user(user)
    visit account_path(user.ssl_account(:default_team).to_slug)
    click_on 'BUY'
    page.all('img[alt="Buy sm bl"]')[0].click
    find('input[alt="submit ssl certificate order"]').click
    find('img[alt="Checkout"]').click
    find('input.order_next').click
    click_on 'Click here to finish processing your ssl.com certificates.'
    click_on 'finish processing'
    fill_in 'certificate_order_certificate_contents_attributes_0_signing_request', with: test_csr
    find('input.submit_csr_img_tag').click
    fill_in 'certificate_order_certificate_contents_attributes_0_registrant_attributes_address1', with: '3100 Richmond'
    fill_in 'certificate_order_certificate_contents_attributes_0_registrant_attributes_postal_code', with: '77098'
    fill_in 'certificate_order_certificate_contents_attributes_0_registrant_attributes_company_number', with: '306384306384'
    find('input[alt="edit ssl certificate order"]').click
    click_on '+ Create New Contact'
    find('#chk-technical-role').set(true)
    fill_in 'contact_first_name', with: user.first_name
    fill_in 'contact_last_name', with: user.last_name
    fill_in 'contact_email', with: user.email
    fill_in 'contact_phone', with: '832-201-7706'
    find('#btn_create_role_contact').click
    find('input[alt="Next bl"]').click
    expect(page).to have_content('Domain Validation')
  end

  def test_csr
    '-----BEGIN CERTIFICATE REQUEST-----
    MIICrjCCAZYCAQAwaTELMAkGA1UEBhMCVVMxFDASBgNVBAMMC2V4YW1wbGUuY29t
    MRAwDgYDVQQHDAdIb3VzdG9uMRAwDgYDVQQKDAdTU0wuY29tMQ4wDAYDVQQIDAVU
    ZXhhczEQMA4GA1UECwwHU1NMLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
    AQoCggEBAMMexVw+K8qzoqK+YRhyEYdxksx79m0KPLo4RHGcDq6pV637ykbT6lTj
    LSymfOH+E/7cnbnO0sQEokvpsYiVLcJGIKNzGJKxWtJpypmEz0nvfN9gZSU4RAh1
    U4MyO3X1TdaCw+K1FvD56V3//rrapHrVg7OprpHZrPoE0cpeh1Jwwqzp+4qqLTnp
    x4+Av/qOMB4hxUgJw9s01keJguEQHzdhE7H6JF8FJTtaf9k0Ze+6I756HA7b/Jx7
    HzvM7vdv8LrRB1qYmTKe3bS3WlXgmWYVZOYb/xG5uGug8ghz/4A4JXTDx/KEb3os
    4nEuwSXB6IzVP1MUj+ZXfitLxqj1KwECAwEAAaAAMA0GCSqGSIb3DQEBCwUAA4IB
    AQBtbUtv6gxSv6v+i+9aIReHsYGjIDM6XgIOrfygcHrMyGBJJQQgirQ90TVolu+C
    kRujfjo01YK/EgSqM0Z+S+lIRjG7OGiQ86pJSdI7ZIy/sD7aOLLw7csA0e/aAJEL
    YkMYAxUPpbRhhRo43WTiR1dN9lhXDQA3zDRsYMFsBqQksM4iR7EP356NSNVvRo/P
    i8uQ1SsfyrOwoCUCopOLdhQq4bzIwuR6mZ2z2ksu9pUZolfArfFq1ByYIDDGXv55
    yKDkQBcnU/oMONsuIsUyr5SKPbLVwSp8k9k61unEt30kYhiUgggbHILusT9hCfBv
    cpJ6EXAChQ0+6c8ND/mik0SG
    -----END CERTIFICATE REQUEST-----'
  end
end
