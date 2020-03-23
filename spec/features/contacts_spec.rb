require 'rails_helper'

RSpec.describe 'Contacts', type: :feature do
  include AuthenticationHelpers

  before(:all) do
    initialize_roles
    initialize_triggers
    initialize_server_software
    initialize_certificates
  end

  let!(:user) { create(:user, :owner) }

  before do
    User.any_instance.stubs(:authenticated_avatar_url).returns('https://github.blog/wp-content/uploads/2012/03/codercat.jpg?fit=896%2C896')
    login
  end

  it 'can add an administrative contact', js: true do
    Authorization::Maintenance.without_access_control do
      user.ssl_account.funded_account.update_attributes(cents: 100_000)
    end

    click_on 'BUY'
    certificate_order = create(:certificate_order, :with_contents, ssl_account_id: user.ssl_account.id)
    visit account_path(user.ssl_account(:default_team).to_slug)
    # visit "/team/#{user.ssl_account.ssl_slug}/certificate_contents/#{certificate_order.certificate_contents.first.ref}"
    expect(page).to have_content(certificate_order.certificate_contents.first.ref)
  end

  def login
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
  end
end
