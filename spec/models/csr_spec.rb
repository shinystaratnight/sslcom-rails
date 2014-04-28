require 'spec_helper'

describe Csr, "as an ssl.com certificate signing request" do
  it "should parse a non ucc csr with accurate results" do
    parsed = Csr.new(body: @lobby_sb_betsoftgaming_com_csr)
    parsed.common_name.should == "lobby.sb.betsoftgaming.com"
    parsed.organization.should == "Betsoftgaming LTD."
    parsed.state.should == "Nicosia"
    parsed.locality.should == "Strovolos"
    parsed.country.should == "CY"
    parsed.sig_alg.should == "sha1WithRSAEncryption"
    parsed.strength.should == 1024
  end

  it "should be able to be created" do
    csr = create(:ssl_danskkabeltv_dk_2048_csr)
  end
end
