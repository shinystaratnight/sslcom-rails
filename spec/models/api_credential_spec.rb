require 'spec_helper'

describe ApiCredential do
  it "is invalid without ssl_account" do
    ac = ApiCredential.new(ssl_account: nil)
    expect(ac).to have(1).errors_on :ssl_account
  end

  it "is valid" do
    expect(create :api_credential).to be_valid
  end

end
