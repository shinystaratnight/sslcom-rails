require 'rails_helper'

describe InvoicesController do
  include SessionHelper
  let!(:user) { create(:user, :sys_admin) }
  let(:invoice) { create(:invoice, billable: user.ssl_account) }

  before do
    activate_authlogic
    login_as(user)
  end

  describe '#update' do
    before do
      patch :update, { invoice: { address_1: 'My new address' },
                       id: invoice.reference_number,
                       format: :json }
      invoice.reload
    end

    it 'executes successfully' do
      expect(response.code).to eq '200'
    end

    it 'changes invoice address' do
      expect(invoice.reload.address_1).to eq 'My new address'
    end
  end
end
