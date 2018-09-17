namespace :cas do
  desc "CA profiles that can be referenced"
  task seed_ejbca_profiles: :environment do
    url=
      if ENV['RAILS_ENV']=="production"
        "192.168.5.17"
      elsif ENV['RAILS_ENV']=="staging"
        "192.168.5.19"
      else
        "192.168.100.5"
      end
    if ENV['RESET']
      CasCertificate.delete_all
      Ca.where{(ref!="0") & (ref!="0017d")}.delete_all
    end
    Ca.find_or_initialize_by(ref: "1000").update_attributes(
      friendly_name: "CertLock SSL RSA 4096 (EV)",
      profile_name: "CertLock-SubCA-EV-SSL-RSA-4096",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1001").update_attributes(
      friendly_name: "CertLock SSL RSA 4096 (DV)",
      profile_name: "CertLock-SubCA-SSL-RSA-4096",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:dvssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1002").update_attributes(
      friendly_name: "CertLock SSL RSA 4096 (OV)",
      profile_name: "CertLock-SubCA-SSL-RSA-4096",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:ovssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1003").update_attributes(
      friendly_name: "CertLock SSL ECC (DV)",
      profile_name: "CertLockECCSSLsubCA",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:dvssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1004").update_attributes(
      friendly_name: "CertLock SSL ECC (OV)",
      profile_name: "CertLockECCSSLsubCA",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:ovssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1005").update_attributes(
      friendly_name: "CertLock SSL ECC (EV)",
      profile_name: "CertLockEVECCSSLsubCA",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl],
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1006").update_attributes(
      friendly_name: "CertLockEVROOTCAECC",
      profile_name: "CertLockEVROOTCAECC",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1007").update_attributes(
      friendly_name: "CertLockEVROOTCARSA",
      profile_name: "CertLockEVROOTCARSA",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1008").update_attributes(
      friendly_name: "CertLockROOTCAECC",
      profile_name: "CertLockROOTCAECC",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1009").update_attributes(
      friendly_name: "CertLockROOTCARSA",
      profile_name: "CertLockROOTCARSA",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::CERTLOCK_CA
    )
    Ca.find_or_initialize_by(ref: "1100").update_attributes(
      friendly_name: "ECOsslcom-RootCA-ECC-384-R1",
      profile_name: "ECOsslcom-RootCA-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::ECOSSL_CA
    )
    Ca.find_or_initialize_by(ref: "1101").update_attributes(
      friendly_name: "ECOsslcom-RootCA-RSA-4096-R1",
      profile_name: "ECOsslcom-RootCA-RSA-4096-R1",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::ECOSSL_CA
    )
    Ca.find_or_initialize_by(ref: "1200").update_attributes(
      friendly_name: "ManagementCA",
      profile_name: "ManagementCA",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::MANAGEMENT_CA
    )
    Ca.find_or_initialize_by(ref: "0001").update_attributes(
      friendly_name: "SSL.com EV CS RSA 4096",
      profile_name: "EV_RSA_CS_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ekus: Ca::EKUS[:code_signing],
      end_entity: Ca::END_ENTITY[:evcs],
      ca_name: "SSL.com-EV-codeSigning-Intermediate-RSA-4096"
    )
    Ca.find_or_initialize_by(ref: "0002").update_attributes(
      friendly_name: "SSLcom-RootCA-ECC-384-R1",
      profile_name: "SSLcom-RootCA-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0003").update_attributes(
      friendly_name: "SSLcom-RootCA-ECC-384-R2",
      profile_name: "SSLcom-RootCA-ECC-384-R2",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0004").update_attributes(
      friendly_name: "SSLcom-RootCA-EV-ECC-384-R1",
      profile_name: "SSLcom-RootCA-EV-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0005").update_attributes(
      friendly_name: "SSLcom-RootCA-EV-ECC-384-R2",
      profile_name: "SSLcom-RootCA-EV-ECC-384-R2",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0006").update_attributes(
      friendly_name: "SSL.com SSL ECC 384 (EV)",
      profile_name: "SSLcom-SubCA-EV-SSL-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl]
    )
    Ca.find_or_initialize_by(ref: "0007").update_attributes(
      friendly_name: "SSL.com SSL ECC 384 (DV)",
      profile_name: "SSLcom-SubCA-SSL-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:dvssl]
    )
    Ca.find_or_initialize_by(ref: "0008").update_attributes(
      friendly_name: "SSL.com SSL ECC 384 (OV)",
      profile_name: "SSLcom-SubCA-SSL-ECC-384-R1",
      algorithm: "ecc",
      size: 384,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:ovssl]
    )
    Ca.find_or_initialize_by(ref: "0009").update_attributes(
      friendly_name: "SSLcom-RootCA-EV-RSA-4096-R2",
      profile_name: "SSLcom-RootCA-EV-RSA-4096-R2",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0010").update_attributes(
      friendly_name: "SSLcom-RootCA-EV-RSA-4096-R3",
      profile_name: "SSLcom-RootCA-EV-RSA-4096-R3",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0011").update_attributes(
      friendly_name: "SSLcom-RootCA-RSA-4096-R1",
      profile_name: "SSLcom-RootCA-RSA-4096-R1",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0012").update_attributes(
      friendly_name: "SSLcom-RootCA-RSA-4096-R2",
      profile_name: "SSLcom-RootCA-RSA-4096-R2",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0013").update_attributes(
      friendly_name: "SSL.com CS RSA 4096",
      profile_name: "RSA_CS_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
      ekus: [Ca::EKUS[:code_signing]],
      end_entity: Ca::END_ENTITY[:cs]
    )
    Ca.find_or_initialize_by(ref: "0014").update_attributes(
      friendly_name: "SSL.com EV CS RSA 4096 R2",
      profile_name: "EV_RSA_CS_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R2",
      ekus: [Ca::EKUS[:code_signing]],
      end_entity: Ca::END_ENTITY[:evcs]
    )
    Ca.find_or_initialize_by(ref: "0015").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 R2 (EV)",
      profile_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R2",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl]
    )
    Ca.find_or_initialize_by(ref: "0016").update_attributes(
      friendly_name: "SSL.com EV TimeStamping RSA 4096",
      profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:time_stamping]]
    )
    Ca.find_or_initialize_by(ref: "0017").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 (DV)",
      profile_name: "DV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:dvssl]
    )
    Ca.find_or_initialize_by(ref: "0018").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 (OV)",
      profile_name: "OV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:ovssl]
    )
    Ca.find_or_initialize_by(ref: "0019").update_attributes(
      friendly_name: "SSLcomEVROOTCARSA",
      profile_name: "SSLcomEVROOTCARSA",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "RootCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA
    )
    Ca.find_or_initialize_by(ref: "0020").update_attributes(
      friendly_name: "SSLcomEVRSASSLsubCA",
      profile_name: "EV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcomEVRSASSLsubCA",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl]
    )
    Ca.find_or_initialize_by(ref: "0021").update_attributes(
      friendly_name: "NAESB Client Cert Rudimentary Assurance",
      profile_name: "OV_RSA_NAESB_RA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "0022").update_attributes(
      friendly_name: "NAESB Client Cert Basic Assurance",
      profile_name: "OV_RSA_NAESB_BA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "0023").update_attributes(
      friendly_name: "NAESB RSA Client Cert High Assurance",
      profile_name: "OV_RSA_NAESB_HA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "0024").update_attributes(
      friendly_name: "NAESB RSA Client Cert Medium Assurance",
      profile_name: "OV_RSA_NAESB_MA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    # Dev ejbca mappings
    Ca.find_or_initialize_by(ref: "0013d").update_attributes(
      friendly_name: "SSL.com CS RSA 4096 (dev)",
      profile_name: "RSA_CS_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
      ekus: [Ca::EKUS[:code_signing]],
      end_entity: Ca::END_ENTITY[:cs]
    )
    Ca.find_or_initialize_by(ref: "0014d").update_attributes(
      friendly_name: "SSL.com EV CS RSA 4096 (dev)",
      profile_name: "EV_RSA_CS_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R2",
      ekus: [Ca::EKUS[:code_signing]],
      end_entity: Ca::END_ENTITY[:evcs]
    )
    Ca.find_or_initialize_by(ref: "0015d").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 R2 (EV) (dev)",
      profile_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R2",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl]
    )
    Ca.find_or_initialize_by(ref: "0016d").update_attributes(
      friendly_name: "SSL.com EV TimeStamping RSA 4096 (dev)",
      profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:time_stamping]]
    )
    Ca.find_or_initialize_by(ref: "0017d").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 (DV) (dev)",
      profile_name: "DV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:dvssl]
    )
    Ca.find_or_initialize_by(ref: "0018d").update_attributes(
      friendly_name: "SSL.com SSL RSA 4096 (OV) (dev)",
      profile_name: "OV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:ovssl]
    )
    Ca.find_or_initialize_by(ref: "0020d").update_attributes(
      friendly_name: "SSLcomEVRSASSLsubCA (dev)",
      profile_name: "EV_RSA_SERVER_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: "SSLcomEVRSASSLsubCA",
      ekus: [Ca::EKUS[:server]],
      end_entity: Ca::END_ENTITY[:evssl]
    )
    Ca.find_or_initialize_by(ref: "0021d").update_attributes(
      friendly_name: "NAESB Client Cert Rudimentary Assurance (dev)",
      profile_name: "OV_RSA_NAESB_RA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "0022d").update_attributes(
      friendly_name: "NAESB Client Cert Basic Assurance (dev)",
      profile_name: "OV_RSA_NAESB_BA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "0023d").update_attributes(
      friendly_name: "NAESB RSA Client Cert High Assurance (dev)",
      profile_name: "OV_RSA_NAESB_HA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
      Ca.find_or_initialize_by(ref: "0024d").update_attributes(
      friendly_name: "NAESB RSA Client Cert Medium Assurance (dev)",
      profile_name: "OV_RSA_NAESB_MA_CERT",
      algorithm: "rsa",
      size: 4096,
      description: "",
      type: "SubCa",
      caa_issuers: ["ssl.com"],
      host: "https://192.168.100.5:8442/restapi",
      admin_host: "https://192.168.100.5:8443",
      ca_name: Ca::SSLCOM_CA,
      ekus: [Ca::EKUS[:client]],
      end_entity: Ca::END_ENTITY[:ov_client]
    )
    Ca.find_or_initialize_by(ref: "3000").update_attributes(
      friendly_name: "DV_SERVER_CERT_EE",
      profile_name: "DV_SERVER_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Ca.find_or_initialize_by(ref: "3001").update_attributes(
      friendly_name: "OV_SERVER_CERT_EE",
      profile_name: "OV_SERVER_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Ca.find_or_initialize_by(ref: "3002").update_attributes(
      friendly_name: "EV_SERVER_CERT_EE",
      profile_name: "EV_SERVER_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Ca.find_or_initialize_by(ref: "3003").update_attributes(
      friendly_name: "CS_CERT_EE",
      profile_name: "CS_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Ca.find_or_initialize_by(ref: "3004").update_attributes(
      friendly_name: "EV_CS_CERT_EE",
      profile_name: "EV_CS_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Ca.find_or_initialize_by(ref: "3005").update_attributes(
      friendly_name: "OV_CLIENTAUTH_CERT_EE",
      profile_name: "OV_CLIENTAUTH_CERT_EE",
      algorithm: "",
      size: 4096,
      description: "",
      type: "EndEntityProfile"
    )
    Certificate.all.each {|cert|
      Ca.all.each {|ca|
        status = ca.ref=~/d\Z/ ? CasCertificate::STATUS[:shadow] : CasCertificate::STATUS[:active]
        unless ca.is_a?(EndEntityProfile) or ca.is_a?(RootCa) or ca.ekus.blank?
          if cert.is_evcs? and ca.end_entity==(Ca::END_ENTITY[:evcs])
            cert.cas_certificates.create(ca_id: ca.id,
               status: CasCertificate::STATUS[ca.ref=="0014" ? :default : status])
          elsif cert.is_cs? and ca.end_entity==(Ca::END_ENTITY[:cs])
            cert.cas_certificates.create(ca_id: ca.id,
               status: CasCertificate::STATUS[ca.ref=="0013" ? :default : status])
          elsif  cert.is_dv? or cert.is_ov? or cert.is_ev?
            if ca.end_entity==(Ca::END_ENTITY[:dvssl])
              cert.cas_certificates.create(ca_id: ca.id,
               status: CasCertificate::STATUS[(cert.is_ucc? and ca.ref=="0017") ? :default : status])
            elsif (cert.is_ov? or cert.is_ev?) and ca.end_entity==(Ca::END_ENTITY[:ovssl])
              cert.cas_certificates.create(ca_id: ca.id,
               status: CasCertificate::STATUS[cert.is_ucc? ? status : status])
            elsif cert.is_ev? and ca.end_entity==(Ca::END_ENTITY[:evssl])
              cert.cas_certificates.create(ca_id: ca.id,
               status: CasCertificate::STATUS[cert.is_ucc? ? status : status])
            end
          end
        end
      }
    }
  end
end
