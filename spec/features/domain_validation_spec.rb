require 'rails_helper'

RSpec.describe 'DomainValidations', type: :feature do
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
      within '#dcv_validate' do
        fill_in 'validate_code', with: '-----------------'
      end
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
      within '#dcv_validate' do
        fill_in 'validate_code', with: '-----------------'
      end
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content('No domains have been validated.')
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
