# frozen_string_literal: true

module SetupHelpers
  def create_roles
    Role::ALL.each { |role_name| Role.find_or_create_by(name: role_name) }
  end

  def set_common_roles
    @all_roles           = [Role.get_owner_id, Role.get_account_admin_id]
    @billing_role        = [Role.get_role_id(Role::BILLING)]
    @acct_admin_role     = [Role.get_account_admin_id]
    @owner_role          = [Role.get_owner_id]
    @validations_role    = [Role.get_role_id(Role::VALIDATIONS)]
    @installer_role      = [Role.get_role_id(Role::INSTALLER)]
    @users_manager_role  = [Role.get_role_id(Role::USERS_MANAGER)]
  end

  def owner_role
    [Role.get_owner_id]
  end

  def initialize_roles
    create_roles
    set_common_roles
    @password = 'Testing@1'
  end

  def stub_roles
    roles = Role.all
    role_set = []
    Role::ALL.each_with_index do |r, i|
      role_set << build_stubbed(:role, name: r.downcase, id: i)
    end
    roles.stubs(:[]).returns(role_set)
    Role.stubs(:where).returns(roles)
  end

  def initialize_certificates
    %i[evuccssl uccssl evssl ovssl freessl wcssl basicssl premiumssl codesigningssl evcodesigningssl].each do |trait|
      create(:certificate, trait)
    end
  end

  def stub_server_software
    software = ServerSoftware.all
    software_set = []
    ['Apache-ModSSL', 'Oracle', 'Amazon Load Balancer'].each_with_index do |s, i|
      software_set << build_stubbed(:server_software, title: s, id: i)
    end
    software.stubs(:[]).returns(software_set)
    ServerSoftware.stubs(:where).returns(software)
  end

  def initialize_server_software
    ['Apache-ModSSL', 'Oracle', 'Amazon Load Balancer'].each{ |title| ServerSoftware.find_or_create_by(title: title) }
  end

  def stub_server_software
    software = ServerSoftware.all
    software_set = []
    ['Apache-ModSSL', 'Oracle', 'Amazon Load Balancer'].each_with_index do |s, i|
      software_set << build_stubbed(:server_software, title: s, id: i)
    end
    software.stubs(:[]).returns(software_set)
    ServerSoftware.stubs(:where).returns(software)
  end

  def login(role: :owner)
    @user = create(:user, role)
    login_as(@user)
    @user
  end

  def stub_login(role: :owner)
    @user = build_stubbed(:user, id: rand(1000))
    ApplicationController.any_instance.stubs(:current_user).returns(@user)
  end

  def create_and_approve_user(invited_ssl_acct, login = nil, roles = nil)
    set_roles = roles || @acct_admin_role
    new_user  = login.nil? ? create(:user, :owner) : create(:user, :owner, login: login)
    new_user.ssl_accounts << invited_ssl_acct
    new_user.set_roles_for_account(invited_ssl_acct, set_roles)
    new_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    new_user
  end

  def approve_user_for_account(invited_ssl_acct, invited_user)
    invited_user.ssl_accounts << invited_ssl_acct
    invited_user.set_roles_for_account(invited_ssl_acct, @acct_admin_role)
    invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    invited_user
  end

  def initialize_countries
    Country.create(iso1_code: 'US', name_caps: 'UNITED STATES', name: 'United States', iso3_code: 'USA', num_code: 840)
    Country.create(iso1_code: 'ZA', name_caps: 'SOUTH AFRICA', name: 'South Africa', iso3_code: 'ZAF', num_code: 710)
    Country.create(iso1_code: 'CA', name_caps: 'CANADA', name: 'Canada', iso3_code: 'CAN', num_code: 124)
  end

  def initialize_certificate_csr_keys
    @nonwildcard_csr = <<~EOS
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

    @nonwildcard_certificate = <<~EOS
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

    @wildcard_csr = <<~EOS
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

    @wildcard_certificate = <<~EOS
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

    @nonwildcard_certificate_sslcom = <<~EOS
      -----BEGIN CERTIFICATE-----
      MIII3DCCB8SgAwIBAgIRAJa6WYNM1rUAGOtMiP8+17QwDQYJKoZIhvcNAQELBQAw
      gYwxCzAJBgNVBAYTAlVTMRAwDgYDVQQKEwdTU0wuY29tMTUwMwYDVQQLEyxDb250
      cm9sbGVkIGJ5IENPTU9ETyBleGNsdXNpdmVseSBmb3IgU1NMLmNvbTEUMBIGA1UE
      CxMLd3d3LnNzbC5jb20xHjAcBgNVBAMTFVNTTC5jb20gUHJlbWl1bSBFViBDQTAe
      Fw0xNjExMTUwMDAwMDBaFw0xODExMTkyMzU5NTlaMIIBJDEWMBQGA1UEBRMNTlYy
      MDA4MTYxNDI0MzETMBEGCysGAQQBgjc8AgEDEwJVUzEXMBUGCysGAQQBgjc8AgEC
      EwZOZXZhZGExHTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMQswCQYDVQQG
      EwJVUzEOMAwGA1UEERMFNzcwMjUxDjAMBgNVBAgTBVRleGFzMRAwDgYDVQQHEwdI
      b3VzdG9uMR0wGwYDVQQJExQyNjE3IFcgSG9sY29tYmUgQmx2ZDERMA8GA1UEChMI
      U1NMIENvcnAxETAPBgNVBAsTCFNlY3VyaXR5MSMwIQYDVQQLExpDT01PRE8gRVYg
      TXVsdGktRG9tYWluIFNTTDEUMBIGA1UEAxMLd3d3LnNzbC5jb20wggIiMA0GCSqG
      SIb3DQEBAQUAA4ICDwAwggIKAoICAQCzHYqM41eg2MPvFbkQXdeRwxZG1TDLJ4bd
      JFNrs1n5qIVXXOLpgXYe87nxZ121sQBmsveBqp+hO7mME+gDl6/MUgzmuMOs4QVb
      0CrqozYUkX5RquzSC8dUsSz6gEZmD/GBPbI+4UXJb499hpETqfcTAdHwDdBxx7Eq
      UTyLlySvT1d7vEvri5wa3qBv4giD2E8Elyo+Rzpo86uyyFG/VVob9uZ9F3QgzzdL
      ONvj+9ieUaaUnPWbUc5udxVkuo7bBDNYuyodon2+bMRK3oN0i5zc3w+RGX1zIeN3
      GAi8mP9WjsYO2J4H3ru0oWLVhjCq/X+iEYghlNrN1uRbWMXwmlpC8zkhIsSbt6te
      i0mGXLB8dCBaDobRyWi62g8bwzpKe2sJyllN/5aBOuG++GiqK++o4+hrlu/ABiFJ
      WpuguzUQK6Z2cB+mFV1lkxzUYm8sblQD5ACzNyDbKrvQMLb++PVaKpnMKfCVvLoA
      o9T5KfzWAXzpwp5tjgEhxMD3w5xmSmCjuNvuPmIJ3GVigSNbUoZtuco9vjZfBi1k
      0Bpt4oeJinG3lozdNHNCBgQlBvUt5jbOek0EM9UWnbHcG5+bq5C3ZDntMoTcRJco
      1T0V+L04kYIIzUfAtDy4SkyS6JL30xweVlMJDGC4hFNShkJBm7nJTXxclu+BowQK
      xC/83ip/xwIDAQABo4IDnDCCA5gwHwYDVR0jBBgwFoAUfVUE0fc1fCJxP0vmVxLD
      i5qldGswHQYDVR0OBBYEFJOpRouZwPeX+k6ym3CNV/eM8eY2MA4GA1UdDwEB/wQE
      AwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcD
      AjBCBgNVHSAEOzA5MDcGDCsGAQQBsjEBAgEFATAnMCUGCCsGAQUFBwIBFhlodHRw
      czovL2Nwcy51c2VydHJ1c3QuY29tMDsGA1UdHwQ0MDIwMKAuoCyGKmh0dHA6Ly9j
      cmwuc3NsLmNvbS9TU0xjb21QcmVtaXVtRVZDQV8yLmNybDBnBggrBgEFBQcBAQRb
      MFkwNgYIKwYBBQUHMAKGKmh0dHA6Ly9jcnQuc3NsLmNvbS9TU0xjb21QcmVtaXVt
      RVZDQV8yLmNydDAfBggrBgEFBQcwAYYTaHR0cDovL29jc3Auc3NsLmNvbTCBqwYD
      VR0RBIGjMIGgggt3d3cuc3NsLmNvbYIPYW5zd2Vycy5zc2wuY29tggtmYXEuc3Ns
      LmNvbYIMaW5mby5zc2wuY29tgg1saW5rcy5zc2wuY29tghByZXNlbGxlci5zc2wu
      Y29tgg5zZWN1cmUuc3NsLmNvbYIHc3NsLmNvbYIPc3VwcG9ydC5zc2wuY29tggtz
      d3Muc3NsLmNvbYINdG9vbHMuc3NsLmNvbTCCAX8GCisGAQQB1nkCBAIEggFvBIIB
      awFpAHcAaPaY+B9kgr46jO65KB1M/HFRXWeT1ETRCmesu09P+8QAAAFYZ/JcMgAA
      BAMASDBGAiEA/ec0V0plrMB+0KSXP+0KyPv69Kx0EzFFv1F6/WoWV+UCIQDZ/WLB
      0g2ycIAP+t0jp7Z4JJ/XSCOPMKnlR6M1wM/9owB2AFYUBpov18Ls0/XhvUSyPsdG
      drm8mRFcwO+UmFXWidDdAAABWGfyWw4AAAQDAEcwRQIhAKUbSd2kXLrNq5j9YRMZ
      k4Jsl2ZC7185Mf/k2ixT3hCJAiBRzPEOPZKajGfkx++EiB8kREbqIYNDKQcUYhKz
      hdldtwB2AO5Lvbd1zmC64UJpH6vhnmajD35fsHLYgwDEe4l6qP3LAAABWGfyW7wA
      AAQDAEcwRQIgGkyMr+89Npj6/yXqd8VlJIezz6MZjpV2kCvdK3LTYggCIQDv2BBv
      89ZdXI52XSpwZCzovg9jCdtMoZmbIn1WQ91cGjANBgkqhkiG9w0BAQsFAAOCAQEA
      CDTJYuiy1OIM9ANwgZ8l4xqglekH/d4PsfPFjNOwKi+RUYbuBlEGXopd/46t48pq
      KvocUwfek+HA6KzxzB2QkznEJbVsi98KpUnYYJJHzGqGx1dQbv8fSw1nfZCFKuX2
      5tvfYBG70LhfZl5KMAMRxR0Sejoej0j8oHEiD4Q/bo0FH9hqCdwMFCtqTME/Zaiw
      OvZebJkNs5p6xMXD/fzJSeMhOH9SCaX3766NX67FJAlkbHfckHcGqpj8juk7XwJr
      dzjZDgC+M57ZZoDKeAtz+3BGw9Uub9qX+7M+A0WUyPEIs1Wk36ha+RS+gv/DCCF+
      7P7OYpW6l9uLM/2VovklYA==
      -----END CERTIFICATE-----
    EOS
  end

  def initialize_triggers
    (1..5).to_a.each { |i| ReminderTrigger.create(id: i, name: i) } unless ReminderTrigger.count == 5
  end

  def stub_triggers
    triggers = ReminderTrigger.all
    trigger_set = []
    (1..5).to_a.each { |i| trigger_set << build_stubbed(:reminder_trigger, id: i, name: i) }
    triggers.stubs(:[]).returns(trigger_set)
    ReminderTrigger.stubs(:where).returns(triggers)
  end

  def stub_ssl_account_initial_setup
    SslAccount.any_instance.stubs(:initial_setup).returns(true)
  end
end
