# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FundedAccount', type: :feature do
  before do
    ActionController::Base.allow_forgery_protection = true
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  context 'when allocate funds' do
    let(:user) { create(:user, :owner, :billing_profile) }
    let(:amount) { 10.50 }

    context 'with successful' do
      it 'by existed card', js: true do
        as_user(user) do
          visit_deposit_funds_with(amount)
          click_on 'load_funds'
          expected_success_funding(amount)
        end
      end

      it 'by enter new card', js: true do
        as_user(user) do
          visit_deposit_funds_with(amount)
          click_on 'expand_register_card'
          input_payment_information
          click_on 'load_funds'
          expected_success_funding(amount)
        end
      end
    end

    context 'with errors' do
      it 'amount can not less than 10 cents', js: true do
        as_user(user) do
          visit_deposit_funds_with(9)
          click_on 'load_funds'
          expect(page).to have_field('funded_account[amount]', with: 9)
        end
      end
    end
  end

  def expected_success_funding(amount)
    expect(page).to have_selector '.notice', text: 'This transaction has been approved'
    expect(page).to have_content "load amount: #{Money.new(amount * 100).format} USD"
    visit account_path
    expect(page).to have_content "available funds: #{Money.new(amount * 100).format}"
  end

  def visit_deposit_funds_with(amount)
    visit account_path
    click_on 'deposit funds'
    fill_in 'funded_account[amount]', with: amount
  end
end
