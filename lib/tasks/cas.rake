namespace :cas do
  desc "CA profiles that can be referenced"
  task seed_ejbca_profiles: :environment do
    Ca.create!([{
                      ref: "1000",
                      friendly_name: "",
                      profile_name: "CertLock-SubCA-EV-SSL-RSA-4096",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                  },
                  {
                      ref: "1001",
                      friendly_name: "",
                      profile_name: "CertLock-SubCA-SSL-RSA-4096",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                  },
                  {
                      ref: "1002",
                      friendly_name: "",
                      profile_name: "CertLockECCSSLsubCA",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                  },
                  {
                      ref: "1003",
                      friendly_name: "",
                      profile_name: "CertLockEVECCSSLsubCA",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1004",
                      friendly_name: "",
                      profile_name: "CertLockEVROOTCAECC",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1005",
                      friendly_name: "",
                      profile_name: "CertLockEVROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1006",
                      friendly_name: "",
                      profile_name: "CertLockROOTCAECC",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1007",
                      friendly_name: "",
                      profile_name: "CertLockROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1008",
                      friendly_name: "",
                      profile_name: "ECOsslcom-RootCA-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1009",
                      friendly_name: "",
                      profile_name: "ECOsslcom-RootCA-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1010",
                      friendly_name: "",
                      profile_name: "ManagementCA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1011",
                      friendly_name: "",
                      profile_name: "SSL.com-EV-codeSigning-Intermediate-RSA-4096",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1012",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1013",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-ECC-384-R2",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1014",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1015",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-ECC-384-R2",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1016",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-SSL-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1017",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-SSL-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1018",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1019",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-RSA-4096-R3",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1020",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1021",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1022",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1023",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1024",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1025",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1026",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1027",
                      friendly_name: "",
                      profile_name: "SSLcomEVROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "1028",
                      friendly_name: "",
                      profile_name: "SSLcomEVRSASSLsubCA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "subCA",
                      caa_issuers: "ssl.com",
                      host: "https://192.168.100.5:8442/restapi",
                      admin_host: "https://192.168.100.5:8443"
                },
                  {
                      ref: "2000",
                      friendly_name: "",
                      profile_name: "DV_RSA_SERVER_CERT",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "2001",
                      friendly_name: "",
                      profile_name: "OV_RSA_SERVER_CERT",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "2002",
                      friendly_name: "",
                      profile_name: "EV_RSA_SERVER_CERT",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "2003",
                      friendly_name: "",
                      profile_name: "DV_ECC_SERVER_CERT",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "2004",
                      friendly_name: "",
                      profile_name: "OV_ECC_SERVER_CERT",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "2005",
                      friendly_name: "",
                      profile_name: "EV_ECC_SERVER_CERT",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "certificate_profile"
                  },
                  {
                      ref: "3000",
                      friendly_name: "",
                      profile_name: "DV_SERVER_CERT_EE",
                      algorithm: "",
                      size: 4096,
                      description: "",
                      profile_type: "end_entity_profile"
                  },
                  {
                      ref: "3001",
                      friendly_name: "",
                      profile_name: "OV_SERVER_CERT_EE",
                      algorithm: "",
                      size: 4096,
                      description: "",
                      profile_type: "end_entity_profile"
                  },
                  {
                      ref: "3002",
                      friendly_name: "",
                      profile_name: "EV_SERVER_CERT_EE",
                      algorithm: "",
                      size: 4096,
                      description: "",
                      profile_type: "end_entity_profile"
                  },
                  {
                      ref: "3003",
                      friendly_name: "",
                      profile_name: "CS_CERT_EE",
                      algorithm: "",
                      size: 4096,
                      description: "",
                      profile_type: "end_entity_profile"
                  },
                  {
                      ref: "3004",
                      friendly_name: "",
                      profile_name: "EV_CS_CERT_EE",
                      algorithm: "",
                      size: 4096,
                      description: "",
                      profile_type: "end_entity_profile"
                  }])
    Certificate.all.each {|cert|
      Ca.all.each {|ca|
        cert.cas << ca
      }
    }
  end
end
