require 'spec_helper'

describe SslAccount do
  context 'reseller' do
    it "has 1000.00 in the account" do
        expect(create(:ssl_account_reseller).funded_account.cents).to eq(100000)
      end
  end
end
