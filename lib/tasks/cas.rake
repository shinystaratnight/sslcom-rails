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
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1001",
                      friendly_name: "",
                      profile_name: "CertLock-SubCA-SSL-RSA-4096",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1002",
                      friendly_name: "",
                      profile_name: "CertLockECCSSLsubCA",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1003",
                      friendly_name: "",
                      profile_name: "CertLockEVECCSSLsubCA",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1004",
                      friendly_name: "",
                      profile_name: "CertLockEVROOTCAECC",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1005",
                      friendly_name: "",
                      profile_name: "CertLockEVROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1006",
                      friendly_name: "",
                      profile_name: "CertLockROOTCAECC",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1007",
                      friendly_name: "",
                      profile_name: "CertLockROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1008",
                      friendly_name: "",
                      profile_name: "ECOsslcom-RootCA-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1009",
                      friendly_name: "",
                      profile_name: "ECOsslcom-RootCA-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1010",
                      friendly_name: "",
                      profile_name: "ManagementCA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1011",
                      friendly_name: "",
                      profile_name: "SSL.com-EV-codeSigning-Intermediate-RSA-4096",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1012",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1013",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-ECC-384-R2",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1014",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1015",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-ECC-384-R2",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1016",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-SSL-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1017",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-SSL-ECC-384-R1",
                      algorithm: "ecc",
                      size: 384,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1018",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1019",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-EV-RSA-4096-R3",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1020",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1021",
                      friendly_name: "",
                      profile_name: "SSLcom-RootCA-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1022",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1023",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1024",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R2",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1025",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1026",
                      friendly_name: "",
                      profile_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1027",
                      friendly_name: "",
                      profile_name: "SSLcomEVROOTCARSA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  },
                  {
                      ref: "1028",
                      friendly_name: "",
                      profile_name: "SSLcomEVRSASSLsubCA",
                      algorithm: "rsa",
                      size: 4096,
                      description: "",
                      profile_type: "ca_name"
                  }])
  end
end
