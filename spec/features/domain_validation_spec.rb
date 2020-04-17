require 'rails_helper'

RSpec.describe 'DomainValidations', type: :feature do
  include CsrHelpers

  before do
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  context 'with email dcv method' do
    let(:user) { create(:user, :owner) }

    it 'can start email validation', js: true do
      domain = Faker::Internet.domain_name
      login
      visit '/domains'
      click_on 'add'
      fill_in 'domain_names', with: domain
      click_on 'Save'
      click_on 'Pending Validation'
      all('#dcv_methods option')[1].select_option
      find('input[value="Validate"]').click
      DomainControlValidation.any_instance.stubs(:validate).returns(true)
      fill_validation_code
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content("The following domains are now validated: #{domain}")
    end

    it 'shows error when using incorrect validation code', js: true do
      domain = Faker::Internet.domain_name
      login
      visit '/domains'
      click_on 'add'
      fill_in 'domain_names', with: domain
      click_on 'Save'
      click_on 'Pending Validation'
      all('#dcv_methods option')[1].select_option
      find('input[value="Validate"]').click
      fill_validation_code
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content('No domains have been validated.')
    end
  end

  context 'with cname dcv method' do
    let(:user) { create(:user, :owner) }

    it 'processes cname validation', js: true do
      stub_request(:any, 'https://secure.trust-provider.com/products/!GetMDCDomainDetails').to_return(status: 200, body: '')
      stub_request(:any, 'https://secure.trust-provider.com/products/!AutoReplaceSSL').to_return(status: 200, body: '')
      as_user(user) do
        purchase_certificate
        submit_payment_information
        process_certificate
        add_contact
        within 'select[name="domains[example.com][dcv]"]' do
          within 'optgroup[label="Validation via csr hash"]' do
            find('option[value="cname_csr_hash"]').select_option
          end
        end
        accept_confirm do
          find('input[value="Validate"]').click
        end

        expected = find('span[alt="domains[example.com][dcv]"]').text.split(' -> ')
        content = expected.last
        Resolv::DNS.stubs(:open).returns([Resolv::DNS::Resource::IN::CNAME.new(content)])
        CertificateName.any_instance.stubs(:dcv_verify).returns(true)
        within 'select[name="domains[example.com][dcv]"]' do
          within 'optgroup[label="Validation via csr hash"]' do
            find('option[value="https_csr_hash"]').select_option
          end
        end
        within 'select[name="domains[example.com][dcv]"]' do
          within 'optgroup[label="Validation via csr hash"]' do
            find('option[value="cname_csr_hash"]').select_option
          end
        end
        accept_confirm do
          click_on 'Validate'
        end
        click_on 'Premium EV Certificate Order'
        expect(page).to have_content('Certificate For example.com')
      end
    end
  end

  %w[https_csr_hash http_csr_hash].each do |protocol|
    context "with #{protocol} dcv method" do
      let(:user) { create(:user, :owner) }

      it 'passes when expected file is found', js: true do
        stub_request(:any, 'https://secure.trust-provider.com/products/!GetMDCDomainDetails').to_return(status: 200, body: '')
        stub_request(:any, 'https://secure.trust-provider.com/products/!AutoReplaceSSL').to_return(status: 200, body: '')
        as_user(user) do
          purchase_certificate
          submit_payment_information
          process_certificate
          add_contact
          within 'select[name="domains[example.com][dcv]"]' do
            within 'optgroup[label="Validation via csr hash"]' do
              find("option[value='#{protocol}']").select_option
            end
          end
          accept_confirm do
            find('input[value="Validate"]').click
          end

          CertificateName.any_instance.stubs(:dcv_verify).returns(true)
          within 'select[name="domains[example.com][dcv]"]' do
            within 'optgroup[label="Validation via csr hash"]' do
              find('option[value="cname_csr_hash"]').select_option
            end
          end
          within 'select[name="domains[example.com][dcv]"]' do
            within 'optgroup[label="Validation via csr hash"]' do
              find("option[value='#{protocol}']").select_option
            end
          end
          accept_confirm do
            click_on 'Validate'
          end
          click_on 'Premium EV Certificate Order'
          expect(page).to have_content('Certificate For example.com')
        end
      end
    end
  end

  def purchase_certificate
    visit account_path(user.ssl_account(:default_team).to_slug)
    visit '/certificates/ev'
    all('img[title="click to buy this certificate"]')[1].click
    find('.submit_csr_img_tag').click
    find('img[alt="Checkout"]').click
    find('.order_next').click
  end

  def process_certificate
    click_on 'Click here'
    fill_in 'certificate_order_certificate_contents_attributes_0_signing_request', with: single_csr
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
    fill_in 'contact_phone', with: Faker::PhoneNumber.cell_phone
    find('#btn_create_role_contact').click
    find('input[alt="Next bl"]').click
  end

  def submit_payment_information
    bp = attributes_for(:billing_profile)
    fill_in :billing_profile_first_name, with: bp[:first_name]
    fill_in :billing_profile_last_name, with: bp[:last_name]
    fill_in :billing_profile_address_1, with: bp[:address_1]
    fill_in :billing_profile_city, with: bp[:city]
    fill_in :billing_profile_state, with: bp[:state]
    fill_in :billing_profile_postal_code, with: bp[:postal_code]
    fill_in :billing_profile_phone, with: bp[:phone]
    fill_in :billing_profile_card_number, with: bp[:card_number]
    fill_in :billing_profile_security_code, with: bp[:security_code]
    within '#billing_profile_expiration_year' do
      all('option')[2].select_option
    end
    find('.order_next').click
  end

  def fill_validation_code
    within '#dcv_validate' do
      fill_in 'validate_code', with: '-----------------'
    end
  end

  def login
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content("username: #{user.login}")
  end
end
