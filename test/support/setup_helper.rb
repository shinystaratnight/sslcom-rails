module SetupHelper
  def create_roles
    roles = [
      Role::RESELLER,
      Role::ACCOUNT_ADMIN,
      Role::OWNER,
      Role::VETTER,
      Role::SYS_ADMIN,
      Role::SUPER_USER
    ]
    unless Role.count == roles.count
      roles.each { |role_name| Role.create(name: role_name) }
    end
  end

  def create_reminder_triggers
    unless ReminderTrigger.count == 5
      (1..5).to_a.each { |i| ReminderTrigger.create(id: i, name: i) }
    end
  end

  def set_common_roles
    @all_roles       = [Role.get_owner_id, Role.get_account_admin_id]
    @acct_admin_role = [Role.get_account_admin_id]
    @owner_role      = [Role.get_owner_id]
  end

  def initialize_roles
    create_reminder_triggers
    create_roles
    set_common_roles
  end

  def initialize_certificates
    create(:certificate, :basicssl) # non-wildcard
    create(:certificate, :evssl)
    create(:certificate, :uccssl)   # multi-domain + wildcard
    create(:certificate, :wcssl)    # wildcard   
  end

  def initialize_server_software
    ['Apache-ModSSL', 'Oracle', 'Amazon Load Balancer'].each{|t| ServerSoftware.create(title: t)}
  end

  def create_and_approve_user(invited_ssl_acct, login=nil)
    new_user = login.nil? ? create(:user, :owner) : create(:user, :owner, login: login)
    new_user.ssl_accounts << invited_ssl_acct
    new_user.set_roles_for_account(invited_ssl_acct, @acct_admin_role)
    new_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    new_user
  end

  def approve_user_for_account(invited_ssl_acct, invited_user)
    invited_user.ssl_accounts << invited_ssl_acct
    invited_user.set_roles_for_account(invited_ssl_acct, @acct_admin_role)
    invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    invited_user
  end

  def initialize_certificate_csr_keys
@nonwildcard_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIICyzCCAbMCAQAwgYUxCzAJBgNVBAYTAnVzMQswCQYDVQQIDAJOWTELMAkGA1UE
BwwCTlkxEjAQBgNVBAoMCUVaT1BTIEluYzELMAkGA1UECwwCSVQxGjAYBgNVBAMM
EXFsaWtkZXYuZXpvcHMuY29tMR8wHQYJKoZIhvcNAQkBFhB2aXNoYWxAZXpvcHMu
Y29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4bN9dc32durQCxr3
EmwIga1oBPAs9V2DRe2SEKMV5gRgn58vzhREBpW57/fvCqZNAVu5OW+Ee35ZXCN9
+BvbMWhvqjvAn67IQSstwRKUo1dGQJ/c9s+4dd1XPw4WqJE/ZmF+VGve4RppJeO1
2ZLoRxYNttHh3BOEZnu9353h5IlXLQuSCx5jBRwabFl2sTiXQJcznPtuZFi2d2Vm
Vrp+TTRHra27s8ISEU9/0ZFOZZAzMeXR3YRDFe5DC9EaZyT/r0e/SNBnOCvkUMqU
m8clnFgQ4hoDwaTgCcUjzXqkr5pSelzv5GpC5lEpeGqzwmtRmS3BCHgyGFfG25+X
6qdwVQIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBAJOLtP3Uu3OcitXVze69tqAr
oBNwDDXpYiahnYtEeu5wA97ywdKJA6hpBPqUvWCDqMomyUrcpSs+cRGMdjAzzygq
Xh9DJf2TbdLDRlHn0w4DW4bL0WQdjDfH4Z/3phmy52dX68bXWpF7+NkY/rUMY/qF
fcytSruPAUsqlsh9TcZWPO3rMOUuNIXSW/uN81/Dgk/5y8tLxeRHDakKkdlFto88
bgKvKGAS6/q17qQvV0TBVcPbooT+nomb2HTZVPVM+G0di4oQrKi7gCf+xd/42aky
0QVjb3rcZNIl112O1p0W2aIyvDO00WC5Wfs+dWWKtc9CgQgeLPHJ2df1ZTSyL9g=
-----END CERTIFICATE REQUEST-----
EOS

@nonwildcard_certificate = <<EOS
-----BEGIN CERTIFICATE-----
MIIExjCCA66gAwIBAgIRAN/PUD/r3mRZLKW9bE17nIIwDQYJKoZIhvcNAQELBQAw
TTELMAkGA1UEBhMCVVMxEDAOBgNVBAoTB1NTTC5jb20xFDASBgNVBAsTC3d3dy5z
c2wuY29tMRYwFAYDVQQDEw1TU0wuY29tIERWIENBMB4XDTE2MTEwNjAwMDAwMFoX
DTE3MDIwNDIzNTk1OVowUjEhMB8GA1UECxMYRG9tYWluIENvbnRyb2wgVmFsaWRh
dGVkMREwDwYDVQQLEwhGcmVlIFNTTDEaMBgGA1UEAxMRcWxpa2Rldi5lem9wcy5j
b20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDhs311zfZ26tALGvcS
bAiBrWgE8Cz1XYNF7ZIQoxXmBGCfny/OFEQGlbnv9+8Kpk0BW7k5b4R7fllcI334
G9sxaG+qO8CfrshBKy3BEpSjV0ZAn9z2z7h13Vc/DhaokT9mYX5Ua97hGmkl47XZ
kuhHFg220eHcE4Rme73fneHkiVctC5ILHmMFHBpsWXaxOJdAlzOc+25kWLZ3ZWZW
un5NNEetrbuzwhIRT3/RkU5lkDMx5dHdhEMV7kML0RpnJP+vR79I0Gc4K+RQypSb
xyWcWBDiGgPBpOAJxSPNeqSvmlJ6XO/kakLmUSl4arPCa1GZLcEIeDIYV8bbn5fq
p3BVAgMBAAGjggGaMIIBljAfBgNVHSMEGDAWgBRGmv38UV58VFNS4pnjszLvkxp/
VjAdBgNVHQ4EFgQUUVi+VKqCHFmZUccidVtaljC69ZQwDgYDVR0PAQH/BAQDAgWg
MAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMEoG
A1UdIARDMEEwNQYKKwYBBAGCqTABATAnMCUGCCsGAQUFBwIBFhlodHRwczovL2Nw
cy51c2VydHJ1c3QuY29tMAgGBmeBDAECATA0BgNVHR8ELTArMCmgJ6AlhiNodHRw
Oi8vY3JsLnNzbC5jb20vU1NMY29tRFZDQV8yLmNybDBgBggrBgEFBQcBAQRUMFIw
LwYIKwYBBQUHMAKGI2h0dHA6Ly9jcnQuc3NsLmNvbS9TU0xjb21EVkNBXzIuY3J0
MB8GCCsGAQUFBzABhhNodHRwOi8vb2NzcC5zc2wuY29tMDMGA1UdEQQsMCqCEXFs
aWtkZXYuZXpvcHMuY29tghV3d3cucWxpa2Rldi5lem9wcy5jb20wDQYJKoZIhvcN
AQELBQADggEBAH/Wl1BU9htC3EcdxK61QvkwyXaigU5eMAr/gslVXo6aQo68825x
dWB8KvU5FuF3uYCk3ivdIBeT7vASbswebI7XCsR21egE6qA95wh5eWGhnK47MalA
USWwW0+PZ8RMowL+qlWANOcN0Iq4xuqnuuvdA/tLyAvL/yNIX1iA3GHeO4CxCcLe
hmGe6/TCn8yb4NqWwCH/AM5hP1jzzvIX5H7tX1x4zYqwxrb4h3ej3dNXUtV++i0T
M7vKz2paw3EPGNly/YqWbU31gIgI3epA9S/qppXIivJdG9+ZTnPhnw50ApvDxhsM
BojNwzoTNeY+pynznFY5oWvSvqWo0Ru8uyU=
-----END CERTIFICATE-----
EOS

@wildcard_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIDAzCCAesCAQAwgaQxCzAJBgNVBAYTAkVTMQ8wDQYDVQQIDAZNYWRyaWQxDzAN
BgNVBAcMBk1hZHJpZDEdMBsGA1UECgwUUHJvbW9sYW5kIE1lZGlhIFMuTC4xFzAV
BgNVBAsMDkNvbXVuaWNhY2lvbmVzMRYwFAYDVQQDDA0qLnJ1YnJpY2FlLmVzMSMw
IQYJKoZIhvcNAQkBFhRzb3BvcnRlQHByb21vbGFuZC5lczCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMQ2GgM3o+hWJFFldWvY2Jkr3TgxB5u/JW1y5PLq
GGW2GYnZX/7XTrmSW7LZx34lpHtT4fpVzu2Xn5Gk2xUMj+9p6Gx3Z7z/vGMJMhUU
0gOE/e8fxL6986DmYs0mkr/ZMhaihLQ1Jstx2AVIb3YgaBB74Q5tNsmjfy0JG+aQ
cnjONLF+Tyc8ef5fEcLoW5qoihyIFq4TQwKwnJDShb2mBP7Hl2Sb+PSOIOy9fPuy
M1PoN+X/uQvRQyzjLeunu1HcGNgjIccqGLGXKINgMXCj0UFC10C30M2DGjC41nI3
sOkW19h89q/BvezJamwHTyFRrb8FgXgV+WHUbhTrYMEHLgcCAwEAAaAZMBcGCSqG
SIb3DQEJBzEKDAhLciN0b29SMzANBgkqhkiG9w0BAQsFAAOCAQEAvzs0Dj3svZkD
AGD6BnMrufENgGwD/o2D1rPgoJWvJ5h9A/7YQetCl2vucXxvJyuCsrvzGzIZD7WB
SSRZMPjvdGKxSua5Od3cAv8jhIrtyIne1WaIxQA68QKD76/SoPTYqPLiEemKGOGy
7WyEg+rlUfIHlJYnG+p9TEMSCBpFpd7OKzjU43rv+hDzEEG0QFn0Qpv8Ep1Vzrms
b0bFDImxB1j8k5mHL4qtVJsONKqVdz7QXsk4nn2G0MoBRF63jGtbiyDN8TfnfGlu
Q53RFQiGG6UALBm7vcebnjtb3eLSgllGZVAmjwNHwazhGkVDmpfSlz4Q6xEyVjmo
4Kx+FA0O+w==
-----END CERTIFICATE REQUEST-----
EOS

@wildcard_certificate = <<EOS
-----BEGIN CERTIFICATE-----
MIIEwTCCA6mgAwIBAgIRALT7bKwKs2CRCFCJvtHgd9wwDQYJKoZIhvcNAQELBQAw
TTELMAkGA1UEBhMCVVMxEDAOBgNVBAoTB1NTTC5jb20xFDASBgNVBAsTC3d3dy5z
c2wuY29tMRYwFAYDVQQDEw1TU0wuY29tIERWIENBMB4XDTE2MTEwNTAwMDAwMFoX
DTE3MTEwNTIzNTk1OVowWzEhMB8GA1UECxMYRG9tYWluIENvbnRyb2wgVmFsaWRh
dGVkMR4wHAYDVQQLExVFc3NlbnRpYWxTU0wgV2lsZGNhcmQxFjAUBgNVBAMMDSou
cnVicmljYWUuZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDENhoD
N6PoViRRZXVr2NiZK904MQebvyVtcuTy6hhlthmJ2V/+1065kluy2cd+JaR7U+H6
Vc7tl5+RpNsVDI/vaehsd2e8/7xjCTIVFNIDhP3vH8S+vfOg5mLNJpK/2TIWooS0
NSbLcdgFSG92IGgQe+EObTbJo38tCRvmkHJ4zjSxfk8nPHn+XxHC6FuaqIociBau
E0MCsJyQ0oW9pgT+x5dkm/j0jiDsvXz7sjNT6Dfl/7kL0UMs4y3rp7tR3BjYIyHH
KhixlyiDYDFwo9FBQtdAt9DNgxowuNZyN7DpFtfYfPavwb3syWpsB08hUa2/BYF4
Fflh1G4U62DBBy4HAgMBAAGjggGMMIIBiDAfBgNVHSMEGDAWgBRGmv38UV58VFNS
4pnjszLvkxp/VjAdBgNVHQ4EFgQUyWDk+/SuEyhlUSdT4d+vnPuwKeowDgYDVR0P
AQH/BAQDAgWgMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
AQUFBwMCMEoGA1UdIARDMEEwNQYKKwYBBAGCqTABATAnMCUGCCsGAQUFBwIBFhlo
dHRwczovL2Nwcy51c2VydHJ1c3QuY29tMAgGBmeBDAECATA0BgNVHR8ELTArMCmg
J6AlhiNodHRwOi8vY3JsLnNzbC5jb20vU1NMY29tRFZDQV8yLmNybDBgBggrBgEF
BQcBAQRUMFIwLwYIKwYBBQUHMAKGI2h0dHA6Ly9jcnQuc3NsLmNvbS9TU0xjb21E
VkNBXzIuY3J0MB8GCCsGAQUFBzABhhNodHRwOi8vb2NzcC5zc2wuY29tMCUGA1Ud
EQQeMByCDSoucnVicmljYWUuZXOCC3J1YnJpY2FlLmVzMA0GCSqGSIb3DQEBCwUA
A4IBAQBiGK2xEhZcav3L+b5OZvf6vVmJF/2IYji8WHJONzLKskvByevZqTS5ZwDb
xigmQSq/CoHvfCax9HfKNL/pEFUHyu/CDj0T+AgDTDCJ8QG5PTrv2tIT0mLEhRsA
17TdfsbO7QHebR+WTiX6Cx1R+V/J9DQvmYlR/73vTfULlB/DYC2B7Hm/JXJpL5sx
yDZYeQBplbjCEWXxCDtjEChwoJ+ALLLK0MD3wzGS00hU7CU2JPE3Eh27iNSllpJf
YLjgJMISWpyHLhmkKTJrIbe8+vudKNp2shVpV5EnBnhXlzignfs7ol22nLOyAtFT
SrRa/yf1C7o+toOB57DEPQDALr2R
-----END CERTIFICATE-----
EOS
  end
end
