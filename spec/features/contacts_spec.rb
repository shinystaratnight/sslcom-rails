require 'rails_helper'

RSpec.describe 'Contacts', type: :feature do
  include AuthenticationHelpers

  let!(:user) { create(:user, :owner) }

  before(:all) do
    initialize_roles
    initialize_triggers
    initialize_server_software
    initialize_certificates
  end

  before do
    login
  end

  it 'can add an administrative contact', js: true do
    certificate_order = create(:certificate_order, :basicssl, ssl_account_id: user.ssl_accounts.first)
    visit "/team/#{user.ssl_account.first.ssl_slug}/certificate_contents/#{certificate_order.certificate_contents.first.ref}"
    expect(page).to have_content(certificate_order.certificate_contents.first.ref)
  end

  def login
    user.deliver_auto_activation_confirmation!
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content("username: #{user.login}")
  end
end
