require 'rails_helper'

RSpec.describe 'DomainValidations', type: :feature do
  before(:all) do
    initialize_roles
    initialize_triggers
  end

  context 'with email dcv method' do
    let(:user) { create(:user, :owner) }
    let!(:domain) { Faker::Internet.domain_name }

    it 'can start email validation', js: true do
      login
      visit '/domains'
      click_on 'add'
      fill_in 'domain_names', with: domain
      click_on 'Save'
      click_on 'Pending Validation'
      first('#dcv_methods option').select_option
      find('input[value="Validate"]').click
      sleep 2
      within '#dcv_validate' do
        fill_in 'validate_code', with: validation_code
      end
      find('input[alt="Bl submit button"]').click
      expect(page).to have_content 'The following domains'
    end
  end

  def login
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content("username: #{user.login}")
  end

  def validation_code
    DomainControlValidation.find_by(subject: domain).identifier
  end
end
