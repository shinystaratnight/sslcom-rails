require 'rails_helper'

RSpec.describe 'DomainValidations', type: :feature do
  let(:user) { create(:user, :owner) }
  let!(:domain) { Faker::Internet.domain_name }

  context 'with email dcv method' do
    it 'can complete email validation', js: true do
      login
      visit '/domains'
      click_on 'add'
      fill_in 'domain_names', with: domain
      click_on 'Save'
      click_on 'Pending Validation'
      first('#dcv_methods option').select_option
      find('input[value="Validate"]').click
      within '#dcv_validate' do
        fill_in 'validate_code', with: validation_code.to_s
      end
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content("The following domains are now validated: #{domain}")
    end

    it 'shows error when using incorrect validation code', js: true do
      login
      visit '/domains'
      click_on 'add'
      fill_in 'domain_names', with: domain
      click_on 'Save'
      click_on 'Pending Validation'
      first('#dcv_methods option').select_option
      find('input[value="Validate"]').click
      within '#dcv_validate' do
        fill_in 'validate_code', with: validation_code.split(//).shuffle.join
      end
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content('No domains have been validated.')
    end
  end

  context 'with cname dcv method' do
    before do
      Authorization::Maintenance.without_access_control do
        user.create_ssl_account if user.ssl_account.nil?
        user.ssl_accounts.first.generate_funded_account
        user.ssl_accounts.first.funded_account.update(cents: 100_000)
      end
      CertificateHelper.stubs(:last_duration_pricing).returns('100.00')
    end

    it 'processes cname validation', js: true do
      login
      purchase_certificate
      add_contact
      # expect(page).to have_content('Domain Validation')
      last('#dcv_methods option').select_option
      find('input[value="Validate"]').click
      within '#dcv_validate' do
        fill_in 'validate_code', with: validation_code.to_s
      end
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content("The following domains are now validated: #{domain}")
    end
  end

  def login
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content("username: #{user.login}")
  end

  def purchase_certificate
    visit account_path(user.ssl_account(:default_team).to_slug)
    click_on 'BUY'
    first('img[alt="Buy sm bl"]')[0].click
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
  end

  def add_contact
    click_on '+ Create New Contact'
    find('#chk-technical-role').set(true)
    fill_in 'contact_first_name', with: user.first_name
    fill_in 'contact_last_name', with: user.last_name
    fill_in 'contact_email', with: user.email
    fill_in 'contact_phone', with: '832-201-7706'
    find('#btn_create_role_contact').click
    find('input[alt="Next bl"]').click
  end

  def validation_code
    DomainControlValidation.find_by(subject: domain).identifier
  end
end
