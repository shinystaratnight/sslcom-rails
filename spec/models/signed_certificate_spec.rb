require 'spec_helper'

describe SignedCertificate, "as an ssl.com signed certificate" do
  it "should parse a signed certificate with accurate results" do
    parsed = SignedCertificate.new(body: @star_arrownet_dk_cert)
    parsed.common_name.should == "*.arrownet.dk"
    parsed.organization.should == "Arrownet A/S"
    parsed.organization_unit.should eql(["CSD", "Hosted by Secure Sockets Laboratories, LLC",
                                          "Comodo PremiumSSL Wildcard"])
    parsed.state.should == "Denmark"
    parsed.locality.should == "Broendby"
    parsed.country.should == "DK"
    parsed.fingerprintSHA.should == "sha1WithRSAEncryption"
    parsed.strength.should == 1024
  end

  it "should parse" do
    sc = SignedCertificate.new
    parsed = OpenSSL::X509::Certificate.new @star_arrownet_dk_cert
    sc.send(:subject_to_array, parsed.subject.to_s).should ==
          [["C", "DK"], ["postalCode", "2620"], ["ST", "Denmark"], ["L", "Broendby"],
           ["street", "Roholmsvej 19"], ["O", "Arrownet A/S"], ["OU", "CSD"],
           ["OU", "Hosted by Secure Sockets Laboratories, LLC"],
           ["OU", "Comodo PremiumSSL Wildcard"], ["CN", "*.arrownet.dk"]]
    parsed.subject.to_s.should == <<-'EOS'.gsub(/[\s\n]+/, " ").strip
      /C=DK/postalCode=2620/ST=Denmark/L=Broendby/street=Roholmsvej 19/O=Arrownet
      A/S/OU=CSD/OU=Hosted by Secure Sockets Laboratories, LLC/OU=Comodo PremiumSSL
      Wildcard/CN=*.arrownet.dk
      EOS
  end

  it "should serialize ou fields" do
    parsed = OpenSSL::X509::Certificate.new @star_corp_crowdfactory_com_2048_cert
    sc = SignedCertificate.new
    sc.ou_array(parsed.subject.to_s).should ==
        ["Operations Group", "Hosted by Secure Sockets Laboratories, LLC", "Comodo PremiumSSL Wildcard"]
  end

  it "should be able to create a zip bundle" do
    @certificate_order = Factory(:completed_unvalidated_dv_certificate_order)
    @certificate_content = Factory(:certificate_content_pending_validation,
      certificate_order: @certificate_order)
    sc = Factory(:signed_certificate, csr: @certificate_content.csr)
    @s=sc.send :create_signed_cert_zip_bundle
    p @s
  end
end
