require 'rubygems'
require 'spork'

Spork.prefork do
  require 'ruby-debug'
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  ENV['CUCUMBER_COLORS']=nil
  $:.unshift(File.dirname(__FILE__) + '/../lib')
  $:.unshift(File.dirname(__FILE__))
  # This file is copied to spec/ when you run 'rails generate rspec:install'

  # For Travis....
  if defined? Encoding
    Encoding.default_external = 'utf-8'
    Encoding.default_internal = 'utf-8'
  end

  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rubygems'
  require 'bundler'
  Bundler.setup

  require 'cucumber'
  $KCODE='u' unless Cucumber::RUBY_1_9

  RSpec.configure do |c|
    c.before do
      ::Term::ANSIColor.coloring = true
    end
  end

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    config.before(:all){
    @lobby_sb_betsoftgaming_com_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIBtTCCAR4CAQAwdTELMAkGA1UEBhMCQ1kxEDAOBgNVBAgTB05pY29zaWExEjAQ
BgNVBAcTCVN0cm92b2xvczEbMBkGA1UEChMSQmV0c29mdGdhbWluZyBMVEQuMSMw
IQYDVQQDExpsb2JieS5zYi5iZXRzb2Z0Z2FtaW5nLmNvbTCBnzANBgkqhkiG9w0B
AQEFAAOBjQAwgYkCgYEAsrTRXbve5Y7dhSorB11hIkHqbKZgxbDPQ2w0BacHIx2U
7M1RtyXaPYizUXHOrjCiCoe9NyivZ9Oip63kfIb5vpArIgVfnM2K2aizcmi6pdj2
kbePrp1Uz86nxxbEso013XWlmu2lgTRTeBETeRFebYzSKH7hHvFR37kaQRIdHckC
AwEAAaAAMA0GCSqGSIb3DQEBBQUAA4GBADAknB7B/3CnvuZUJrH5O6oD3USft4QU
uuMti01ffH4ZyTMfyLdDcd0gdeXPej+JGvScuXPjzpMb92cpfufTRKsTBUG1C2T6
TYrJ9O3d5oKph8nICihGT0fDIqJCzGar6W9ZbL8PiIDL4hFymVUZk409NPfrND1g
yIeY8v/sjOUW
-----END CERTIFICATE REQUEST-----
EOS

  @lobby_sb_betsoftgaming_com_signed_cert = <<EOS
-----BEGIN CERTIFICATE-----
MIIDoDCCAoigAwIBAgIFMUeG4iswDQYJKoZIhvcNAQEFBQAwSDELMAkGA1UEBhMC
VVMxIDAeBgNVBAoTF1NlY3VyZVRydXN0IENvcnBvcmF0aW9uMRcwFQYDVQQDEw5T
ZWN1cmVUcnVzdCBDQTAeFw0xMDA1MDExODE3MDZaFw0xMTA0MjcxODE3MDZaMHAx
CzAJBgNVBAYTAkNZMRAwDgYDVQQIEwdOaWNvc2lhMRAwDgYDVQQHEwdOaWNvc2lh
MRgwFgYDVQQKEw9EaWdpdHVzIExpbWl0ZWQxIzAhBgNVBAMTGmxvYmJ5LnNiLmJl
dHNvZnRnYW1pbmcuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCytNFd
u97ljt2FKisHXWEiQepspmDFsM9DbDQFpwcjHZTszVG3Jdo9iLNRcc6uMKIKh703
KK9n06KnreR8hvm+kCsiBV+czYrZqLNyaLql2PaRt4+unVTPzqfHFsSyjTXddaWa
7aWBNFN4ERN5EV5tjNIofuEe8VHfuRpBEh0dyQIDAQABo4HsMIHpMAkGA1UdEwQC
MAAwHQYDVR0OBBYEFFK4/upUAJGFGUfIHDATHx7ZlERdMB8GA1UdIwQYMBaAFEIy
thb6BP3+XUt6w/33TEAdWkOvMAsGA1UdDwQEAwIFoDATBgNVHSUEDDAKBggrBgEF
BQcDATA0BgNVHR8ELTArMCmgJ6AlhiNodHRwOi8vY3JsLnNlY3VyZXRydXN0LmNv
bS9TVENBLmNybDBEBgNVHSAEPTA7MDkGDGCGSAGG/WQBAQIDATApMCcGCCsGAQUF
BwIBFhtodHRwOi8vc3NsLnRydXN0d2F2ZS5jb20vQ0EwDQYJKoZIhvcNAQEFBQAD
ggEBADWc9B0SZCWfV1twxJGliUSUQOECP8rGlcrbeBfWuhwv+pJh7L9zE+Y233YH
yjEuveGSaz2jUCbFMA1OQZP5xQkrgNyP1HS+TRBhueiEklQ7Y8hl1fJqzN/9dE8L
s6XXG8ikdc5d/TjyAn0uBdvvd6u7cgrj3mFmnaqsrRkxRiEIy9Mar3KEF9NRD/fY
KcU+G+C2Pz1K2UQ6KitgAAJ5LrUXCee8hDyXgqHhsLn0ladREwCI3Nex/tX3vS4u
zRz1OP0WypXzhmrjUKyFiNNBzJRBQOJmJn/+65Ag2RD7sMNT5exOc/jTjG7PIKBN
KwcYNFqMjaFueahoRcU/Xquksb8=
-----END CERTIFICATE-----
EOS

  @star_arrownet_dk_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIB0TCCAToCAQAwgZAxCzAJBgNVBAYTAkRLMRAwDgYDVQQIEwdEZW5tYXJrMREw
DwYDVQQHEwhCcm9lbmRieTEVMBMGA1UEChMMQXJyb3duZXQgQS9TMQwwCgYDVQQL
EwNDU0QxFjAUBgNVBAMUDSouYXJyb3duZXQuZGsxHzAdBgkqhkiG9w0BCQEWEGlu
Zm9AYXJyb3duZXQuZGswgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOYnCB7/
Pc+2XHyxpb1Is3OCgGhCsYXwf6my4on1brYY2IgIE3BLUU/n5f0oZP8jzNntIGHW
XLVPx6x5Sn1n19pP/lGkN9p3ug5NXtK/F7c5CrzBPltdWgykhN1Nkzu0qMAldes2
tFa5rWmd01cH03p5djxShMgLp75Y9NvmIln3AgMBAAGgADANBgkqhkiG9w0BAQQF
AAOBgQCxHoV1wdt7W03wGVPf6Ywkcc6t0zL51CF3HZg3YAFjHYYt0NSGMvXuP3w6
wUDIoXtUsuhxzw8ynNv6bCE0zy00rOwJLNh/odokaxTOkImIXuly8x91ugglOddL
yb5Gu/g2Lig5QzuvMvNw6v4y2eZo22H2gzS2xR97Pexiexx3UQ==
-----END CERTIFICATE REQUEST-----
EOS

  @star_arrownet_dk_cert = <<EOS
-----BEGIN CERTIFICATE-----
MIIFcjCCBFqgAwIBAgIRAJv0VoG7rK1HnFd5FJJhJnUwDQYJKoZIhvcNAQEFBQAw
gZcxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR8wHQYDVQQDExZVVE4tVVNFUkZpcnN0
LUhhcmR3YXJlMB4XDTA5MTEyNTAwMDAwMFoXDTExMTEyNTIzNTk1OVowgfAxCzAJ
BgNVBAYTAkRLMQ0wCwYDVQQREwQyNjIwMRAwDgYDVQQIEwdEZW5tYXJrMREwDwYD
VQQHEwhCcm9lbmRieTEWMBQGA1UECRMNUm9ob2xtc3ZlaiAxOTEVMBMGA1UEChMM
QXJyb3duZXQgQS9TMQwwCgYDVQQLEwNDU0QxMzAxBgNVBAsTKkhvc3RlZCBieSBT
ZWN1cmUgU29ja2V0cyBMYWJvcmF0b3JpZXMsIExMQzEjMCEGA1UECxMaQ29tb2Rv
IFByZW1pdW1TU0wgV2lsZGNhcmQxFjAUBgNVBAMUDSouYXJyb3duZXQuZGswgZ8w
DQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOYnCB7/Pc+2XHyxpb1Is3OCgGhCsYXw
f6my4on1brYY2IgIE3BLUU/n5f0oZP8jzNntIGHWXLVPx6x5Sn1n19pP/lGkN9p3
ug5NXtK/F7c5CrzBPltdWgykhN1Nkzu0qMAldes2tFa5rWmd01cH03p5djxShMgL
p75Y9NvmIln3AgMBAAGjggHgMIIB3DAfBgNVHSMEGDAWgBShcl8mGyiYQ5VdBzfV
hZadS9LDRTAdBgNVHQ4EFgQUqlO4tDuvnBIom6RjRnVXAgle5YcwDgYDVR0PAQH/
BAQDAgWgMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUF
BwMCMEYGA1UdIAQ/MD0wOwYMKwYBBAGyMQECAQMEMCswKQYIKwYBBQUHAgEWHWh0
dHBzOi8vc2VjdXJlLmNvbW9kby5uZXQvQ1BTMHsGA1UdHwR0MHIwOKA2oDSGMmh0
dHA6Ly9jcmwuY29tb2RvY2EuY29tL1VUTi1VU0VSRmlyc3QtSGFyZHdhcmUuY3Js
MDagNKAyhjBodHRwOi8vY3JsLmNvbW9kby5uZXQvVVROLVVTRVJGaXJzdC1IYXJk
d2FyZS5jcmwwcQYIKwYBBQUHAQEEZTBjMDsGCCsGAQUFBzAChi9odHRwOi8vY3J0
LmNvbW9kb2NhLmNvbS9VVE5BZGRUcnVzdFNlcnZlckNBLmNydDAkBggrBgEFBQcw
AYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMCUGA1UdEQQeMByCDSouYXJyb3du
ZXQuZGuCC2Fycm93bmV0LmRrMA0GCSqGSIb3DQEBBQUAA4IBAQCeSd1SG5gbUG8D
AdBW1nR3vAb0s8Hg1DWOAsRwPoNOQWvYeiayUEnYgtWoD2QLhHSxu5qz5LQuKMwW
6MF+5pbwpwiDFv+dKQHz8Ym5MhjgvosJT/vcvR27bQAbryrTT+3jM7vCZ/dA140T
kmGEby8i9wMvG0LmhSDQg1x/CL6sehHoowaNNtZ3sshaekKgUcthkyzOy+y9Hef7
wgu8DujpRyEcAlUXgD+KIKonfUYMRWji/VBZgKjCyuGpK4uL0OmPEnShagLYgGLd
YefSExBnHUItfHe7ABcxH66dPaQHfhForDD9TL8KtSzP3whwSQhQ2uH51J279IfB
EyM422Ir
-----END CERTIFICATE-----
EOS

  @ssl_danskkabeltv_dk_2048_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIC6jCCAdICAQAwgaQxCzAJBgNVBAYTAkRLMRMwEQYDVQQIEwpDb3BlbmhhZ2Vu
MRQwEgYDVQQHEwtBbGJlcnRzbHVuZDEPMA0GA1UECxMGVGVrbmlrMRcwFQYDVQQK
Ew5EYW5zayBLYWJlbCBUVjEcMBoGA1UEAxMTc3NsLmRhbnNra2FiZWx0di5kazEi
MCAGCSqGSIb3DQEJARYTc2xoQGRhbnNra2FiZWx0di5kazCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANG+v2MNf5oD/iQhOuKlBzJRqAFHMj3KuKejfw29
eubsO+PATjwJAoyuN+smnlSjzL8or6Yb1wNaBPbDY3OprO4+KJ7tgMfxnqScrbdi
RuqbhFy2WOs/UmsMyP0Eb7GSf2dPktgvhK8h5Y8lsGpZFpWj05CdewdFYD2THz9f
uonFBk0OsaMKu48wE9exT0PsdtSG5Z2bEYs24gHO4IgqyKtSSsciUBghx161NBX/
1d6xwiXwv25SKEOr2vww/IYUGvfIKZNHDcren2PShmSUE+WW5uTeY18Lbzs51Gxh
MTjRZvrI9VSoxYp3hjh/CIpuIDL/ACe/3Ht90nQ3RAXz0PsCAwEAAaAAMA0GCSqG
SIb3DQEBBQUAA4IBAQDFxzw9pi2agvF6bRl1RxyinfnBLVrZcszp07rEf+D6sLcE
m/hEPcd5cisk/NAOU1YrWZPBmVxyQeNP/9t22P98cZvVxGam257/D/hKLCFvT6O+
8qR/i6wAl19BMX0jLMODNkXHRMHq4v/Uv9DkpejcwvqzcrH2EbKL/ZYgM4e7CtlK
Sv4v5KfdNucQPgoaWB76OFkqmVsLTZAeFhT9+R8c1kXAeaqWk5wSYVyJVofFG5Ox
dqdBYOw9UwEsiFwYYMk6XSRXDPA9ldBYqgb/ck/BxFVFzdLg2p8plZWjuhqcNI9E
wJ4W0jbRq+eaj9c10Q3cPAT65yYggar+AKD7Gr+H
-----END CERTIFICATE REQUEST-----
EOS

  @star_corp_crowdfactory_com_2048_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIC0TCCAbkCAQAwgYsxCzAJBgNVBAYTAnVzMQ8wDQYDVQQIEwZPcmVnb24xETAP
BgNVBAcTCFBvcnRsYW5kMRswGQYDVQQKExJDcm93ZCBGYWN0b3J5IEluYy4xGTAX
BgNVBAsTEE9wZXJhdGlvbnMgR3JvdXAxIDAeBgNVBAMMFyouY29ycC5jcm93ZGZh
Y3RvcnkuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq5f0CVkd
zR6lMoI/ejRvK/8Q+TLOk9SEyKxAx9hpmwf8+qLnt5Et6w1gplpqgjREQj6LMpcj
99gNoRTfkGGu+AO23wOPjmknAPHUEHAoPR3JIv643Dk4vTXGTLTAeoi5equEaq5l
6iz32UtSpROBHPRJjVHg/wC/UkolDT2tfhVOYELyzTW44OkWaVAgvjLEXEu2Wq2J
LZuShvfA6dPHfpgfZVAQD1/ucnlkbDXaGcb/vldgirEND8OvA0uufuKFUOjd+NdQ
eCCxHgN5YiKax4EMZ5Xu3BQK1XNkcbee8pW/fdhPX8ZpraoamgjU1aFfW9GGiKpH
JSl/u5EkcYFl/wIDAQABoAAwDQYJKoZIhvcNAQEFBQADggEBAJiiuHHG3sIfZqqd
J1MYS1S8pp9z8fzwEagl1PseGpr4tzqdI/YyAmsKbJ/5Vcjl7omnH5EbjbrWHxnT
HI/yD9iYzys5APRYuWTsu2062E1oBuqCUZlambofM3OJ3ZOaqKDMuKPOYaZXZ5oa
wo5DnhHydWM5oueaWbMuLv8ydbqolP+MrBhbA8CQp+nlwsxeJHyFhJINL0Ewb/GE
oMFCVp27p9bIE35qpNqOaYAcLxp6wTFTPRg048vpYbZxNfwV07uMTJnge7YdQ9KP
yMi36slJID403aJwthhX8cwWVOLpbBjDG9gcucR1l3TSDW8QVWDMari4ih5mIIQP
xMajgLU=
-----END CERTIFICATE REQUEST-----
EOS
}

  end

  require 'sauce'

  Sauce.config do |conf|
      conf.browser_url = "http://78303.test/"
      conf.browsers = [
          ["Windows 2003", "firefox", "3.6."]
      ]
      conf.application_host = "127.0.0.1"
      conf.application_port = "3001"
  end
end


Spork.each_run do
  # This code will be run each time you run your specs.
  require 'factory_girl_rails'
  FactoryGirl.definition_file_paths = [File.join(Rails.root, 'spec', 'factories')]
  FactoryGirl.find_definitions
end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them
