require 'rails_helper'

RSpec.describe 'Contacts', type: :feature do
  include AuthenticationHelpers

  before(:all) do
    initialize_roles
    initialize_triggers
    initialize_server_software
    initialize_certificates
  end

  it 'can add an administrative contact', js: true do
    create_user
    login_user
    certificate_order = create(:certificate_order, :basicssl, ssl_account_id: @current_user.ssl_accounts.first)
    visit "/team/#{@current_user.ssl_account.first.ssl_slug}/certificate_contents/#{certificate_order.certificate_contents.first.ref}"
    expect(page).to have_content(certificate_order.certificate_contents.first.ref)
  end
end
