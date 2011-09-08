require 'spec_helper'

describe SignedCertificate, "as an ssl.com signed certificate" do
  it "should parse a signed certificate with accurate results" do
    parsed = SignedCertificate.new(body: @star_arrownet_dk_cert)
    parsed.common_name.should == "*.arrownet.dk"
    #parsed.organization.should == "Betsoftgaming LTD."
    #parsed.state.should == "Nicosia"
    #parsed.locality.should == "Strovolos"
    #parsed.country.should == "CY"
    #parsed.sig_alg.should == "sha1WithRSAEncryption"
    #parsed.strength.should == 1024
  end
end
