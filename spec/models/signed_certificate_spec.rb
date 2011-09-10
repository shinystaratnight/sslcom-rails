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

  it "should serialize ou fields" do
    parsed = OpenSSL::X509::Certificate.new @star_corp_crowdfactory_com_2048_cert
    sc = SignedCertificate.new
    sc.ou_array(parsed.subject.to_s).should ==
        ["Operations Group", "Hosted by Secure Sockets Laboratories, LLC", "Comodo PremiumSSL Wildcard"]
  end
end
