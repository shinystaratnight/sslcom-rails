require 'rspec'
require "legacy_ssl_md5"

describe LegacySslMd5, "Legacy algorithm" do
  crypted = "mSTStip/0loOF7njeY/VWeJOvJSRXARD5lT+Af0="

  it "should match actual passwords using the legacy algorithm" do
    plain = "idammopeoje"
    LegacySslMd5.matches?(crypted, plain).should == true
  end

  it "should not match fake passwords using the legacy algorithm" do
    plain = "false"
    LegacySslMd5.matches?(crypted, plain).should == false
  end
end