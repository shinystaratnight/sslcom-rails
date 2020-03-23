require 'rails_helper'

RSpec.feature 'Contacts', type: :feature do
  include AuthenticationHelpers

  it 'can add an administrative contact' do
    create_user
    login_user
    certificate_order = create(:certificate_order, :basicssl, ssl_account_id: @current_user.ssl_accounts.first)
  end
end
