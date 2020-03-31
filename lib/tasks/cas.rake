namespace :cas do
  desc "CA profiles that can be referenced"
  # EJBCA_ENV - Setup CA mappings based on the RA environment
  # DEFAULT_ENV - map this team to a different EJBCA ENV than EJBCA_ENV (only works in ENV['EJBCA_ENV']="production")
  # LIVE - array of products to make default. If specified, will not delete other mappings (unless used with RESET).
  #   If left blank, will delete all mappings and set no CA as default (ie all products will map to Comodo)
  # RESET - set to true to delete all cas_certificates mappings
  # SHADOW - set to DV if you do not want OV or EV shadow certs
  #
  # following example will make NAESB the default for ssl_account_id 492124
  # LIVE=naesb SSL_ACCOUNT_IDS=492124
  #
  # following example will remove all ca mappings for ssl_account_id 492124
  # RESET=true SSL_ACCOUNT_IDS=492124
  #
  # delete all CasCertificates from all teams
  # RESET=true
  #
  # create or update CAs
  # EJBCA_ENV=development RAILS_ENV=production # for sandbox
  #
  # only set all products live for these ssl_accounts but do not modify any other mappings
  # LIVE=all SSL_ACCOUNT_IDS=49213,49214 EJBCA_ENV=development RAILS_ENV=production # for sandbox
  #
  # set all products live for all ssl_accounts
  # LIVE=all EJBCA_ENV=development RAILS_ENV=development # for development
  #
  # set all CA mappings for production all products to staging for SslAccount 15
  # LIVE=all SSL_ACCOUNT_IDS=15 DEFAULT_ENV=staging EJBCA_ENV=production RAILS_ENV=production
  # TODO move `host` from Ca to CasCertificate
  task seed_ejbca_profiles: :environment do
    url,shadow_url=
      case ENV['EJBCA_ENV']
      when "production"
        [SslcomCaApi::PRODUCTION_IP,SslcomCaApi::STAGING_IP]
      when "staging"
        [SslcomCaApi::STAGING_IP,SslcomCaApi::STAGING_IP]
      when "development"
        [SslcomCaApi::DEVELOPMENT_IP,SslcomCaApi::DEVELOPMENT_IP]
      end
    default=
      case ENV['DEFAULT_ENV']
      when "production"
        SslcomCaApi::PRODUCTION_IP
      when "staging"
        SslcomCaApi::STAGING_IP
      when "development"
        SslcomCaApi::DEVELOPMENT_IP
      else
        nil
      end
    if ENV['EJBCA_ENV']
      Ca.find_or_initialize_by(ref: "1000").update_attributes(
          friendly_name: "CertLock SSL RSA 4096 (EV)",
          profile_name: "CertLock-SubCA-EV-SSL-RSA-4096",
          algorithm: "rsa",
          size: 4096,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:evssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1001").update_attributes(
          friendly_name: "CertLock SSL RSA 4096 (DV)",
          profile_name: "CertLock-SubCA-SSL-RSA-4096",
          algorithm: "rsa",
          size: 4096,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:dvssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1002").update_attributes(
          friendly_name: "CertLock SSL RSA 4096 (OV)",
          profile_name: "CertLock-SubCA-SSL-RSA-4096",
          algorithm: "rsa",
          size: 4096,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:ovssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1003").update_attributes(
          friendly_name: "CertLock SSL ECC (DV)",
          profile_name: "CertLockECCSSLsubCA",
          algorithm: "ecc",
          size: 384,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:dvssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1004").update_attributes(
          friendly_name: "CertLock SSL ECC (OV)",
          profile_name: "CertLockECCSSLsubCA",
          algorithm: "ecc",
          size: 384,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:ovssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1005").update_attributes(
          friendly_name: "CertLock SSL ECC (EV)",
          profile_name: "CertLockEVECCSSLsubCA",
          algorithm: "ecc",
          size: 384,
          description: Ca::CERTLOCK_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:evssl],
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1006").update_attributes(
          friendly_name: "CertLockEVROOTCAECC",
          profile_name: "CertLockEVROOTCAECC",
          algorithm: "ecc",
          size: 384,
          description: Ca::CERTLOCK_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1007").update_attributes(
          friendly_name: "CertLockEVROOTCARSA",
          profile_name: "CertLockEVROOTCARSA",
          algorithm: "rsa",
          size: 4096,
          description: Ca::CERTLOCK_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1008").update_attributes(
          friendly_name: "CertLockROOTCAECC",
          profile_name: "CertLockROOTCAECC",
          algorithm: "ecc",
          size: 384,
          description: Ca::CERTLOCK_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1009").update_attributes(
          friendly_name: "CertLockROOTCARSA",
          profile_name: "CertLockROOTCARSA",
          algorithm: "rsa",
          size: 4096,
          description: Ca::CERTLOCK_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::CERTLOCK_CA
      )
      Ca.find_or_initialize_by(ref: "1100").update_attributes(
          friendly_name: "ECOsslcom-RootCA-ECC-384-R1",
          profile_name: "ECOsslcom-RootCA-ECC-384-R1",
          algorithm: "ecc",
          size: 384,
          description: Ca::ECOSSL_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::ECOSSL_CA
      )
      Ca.find_or_initialize_by(ref: "1101").update_attributes(
          friendly_name: "ECOsslcom-RootCA-RSA-4096-R1",
          profile_name: "ECOsslcom-RootCA-RSA-4096-R1",
          algorithm: "rsa",
          size: 4096,
          description: Ca::ECOSSL_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
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
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::MANAGEMENT_CA
      )
      Ca.find_or_initialize_by(ref: "0001").update_attributes(
          friendly_name: "SSL.com EV CS RSA 4096",
          profile_name: "EV_RSA_CS_ULMT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ekus: Ca::EKUS[:code_signing],
          end_entity: Ca::END_ENTITY[:evcs],
          ca_name: "SSL.com-EV-codeSigning-Intermediate-RSA-4096"
      )
      Ca.find_or_initialize_by(ref: "0002").update_attributes(
          friendly_name: "SSLcom-RootCA-ECC-384-R1",
          profile_name: "SSLcom-RootCA-ECC-384-R1",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0003").update_attributes(
          friendly_name: "SSLcom-RootCA-ECC-384-R2",
          profile_name: "SSLcom-RootCA-ECC-384-R2",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0004").update_attributes(
          friendly_name: "SSLcom-RootCA-EV-ECC-384-R1",
          profile_name: "SSLcom-RootCA-EV-ECC-384-R1",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0005").update_attributes(
          friendly_name: "SSLcom-RootCA-EV-ECC-384-R2",
          profile_name: "SSLcom-RootCA-EV-ECC-384-R2",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0006").update_attributes(
          friendly_name: "SSL.com SSL ECC 384 (EV)",
          profile_name: "EV_ECC_SERVER_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-EV-SSL-ECC-384-R2",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:evssl]
      )
      Ca.find_or_initialize_by(ref: "0007").update_attributes(
          friendly_name: "SSL.com SSL ECC 384 (DV)",
          profile_name: "DV_ECC_SERVER_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-SSL-ECC-384-R2",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:dvssl]
      )
      Ca.find_or_initialize_by(ref: "0008").update_attributes(
          friendly_name: "SSL.com SSL ECC 384 (OV)",
          profile_name: "OV_ECC_SERVER_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-SSL-ECC-384-R2",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:ovssl]
      )
      Ca.find_or_initialize_by(ref: "0009").update_attributes(
          friendly_name: "SSLcom-RootCA-EV-RSA-4096-R2",
          profile_name: "SSLcom-RootCA-EV-RSA-4096-R2",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0010").update_attributes(
          friendly_name: "SSLcom-RootCA-EV-RSA-4096-R3",
          profile_name: "SSLcom-RootCA-EV-RSA-4096-R3",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0011").update_attributes(
          friendly_name: "SSLcom-RootCA-RSA-4096-R1",
          profile_name: "SSLcom-RootCA-RSA-4096-R1",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0012").update_attributes(
          friendly_name: "SSLcom-RootCA-RSA-4096-R2",
          profile_name: "SSLcom-RootCA-RSA-4096-R2",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0013").update_attributes(
          friendly_name: "SSL.com CS RSA 4096",
          profile_name: "RSA_CS_ULMT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
          ekus: [Ca::EKUS[:code_signing]],
          end_entity: Ca::END_ENTITY[:cs]
      )
      Ca.find_or_initialize_by(ref: "0014").update_attributes(
          friendly_name: "SSL.com EV CS RSA 4096 R2",
          profile_name: "EV_RSA_CS_ULMT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R3",
          ekus: [Ca::EKUS[:code_signing]],
          end_entity: Ca::END_ENTITY[:evcs]
      )
      Ca.find_or_initialize_by(ref: "0015").update_attributes(
          friendly_name: "SSL.com SSL RSA 4096 R3 (EV)",
          profile_name: "EV_RSA_SERVER_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R3",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:evssl]
      )
      Ca.find_or_initialize_by(ref: "0016").update_attributes(
          friendly_name: "SSL.com EV TimeStamping RSA 4096",
          profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA,
          ekus: [Ca::EKUS[:time_stamping]]
      )
      Ca.find_or_initialize_by(ref: "0017").update_attributes(
          friendly_name: "SSL.com SSL RSA 4096 (DV)",
          profile_name: "DV_RSA_SERVER_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:dvssl]
      )
      Ca.find_or_initialize_by(ref: "0018").update_attributes(
          friendly_name: "SSL.com SSL RSA 4096 (OV)",
          profile_name: "OV_RSA_SERVER_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:ovssl]
      )
      Ca.find_or_initialize_by(ref: "0019").update_attributes(
          friendly_name: "SSLcomEVROOTCARSA",
          profile_name: "SSLcomEVROOTCARSA",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "RootCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: Ca::SSLCOM_CA
      )
      Ca.find_or_initialize_by(ref: "0020").update_attributes(
          friendly_name: "SSLcomEVRSASSLsubCA",
          profile_name: "EV_RSA_SERVER_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R3",
          ekus: [Ca::EKUS[:server]],
          end_entity: Ca::END_ENTITY[:evssl]
      )
      Ca.find_or_initialize_by(ref: "0021").update_attributes(
          friendly_name: "NAESB Client Cert Rudimentary Assurance RSA",
          profile_name: "RSA_NAESB_RA_CLIENT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0022").update_attributes(
          friendly_name: "NAESB Client Cert Basic Assurance RSA",
          profile_name: "RSA_NAESB_BA_CLIENT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0023").update_attributes(
          friendly_name: "NAESB Client Cert High Assurance RSA",
          profile_name: "RSA_NAESB_HA_CLIENT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0024").update_attributes(
          friendly_name: "NAESB Client Cert Medium Assurance RSA",
          profile_name: "RSA_NAESB_MA_CLIENT_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0025").update_attributes(
          friendly_name: "NAESB Client Cert Rudimentary Assurance ECC",
          profile_name: "OV_ECC_NAESB_RA_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-ECC-384-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0026").update_attributes(
          friendly_name: "NAESB Client Cert Basic Assurance ECC",
          profile_name: "OV_ECC_NAESB_BA_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-ECC-384-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0027").update_attributes(
          friendly_name: "NAESB Client Cert High Assurance ECC",
          profile_name: "OV_ECC_NAESB_HA_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-ECC-384-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0028").update_attributes(
          friendly_name: "NAESB RSA Client Cert Medium Assurance ECC",
          profile_name: "OV_ECC_NAESB_MA_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-NAESB-clientAuth-ECC-384-R1",
          ekus: [Ca::EKUS[:client]],
          end_entity: Ca::END_ENTITY[:ov_client]
      )
      Ca.find_or_initialize_by(ref: "0030").update_attributes(
          friendly_name: "SSL.com CS ECC 384",
          profile_name: "ECC_CS_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-CodeSigning-ECC-384-R2",
          ekus: [Ca::EKUS[:code_signing]],
          end_entity: Ca::END_ENTITY[:cs]
      )
      Ca.find_or_initialize_by(ref: "0031").update_attributes(
          friendly_name: "SSL.com EV CS ECC 384 R1",
          profile_name: "EV_ECC_CS_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-EV-CodeSigning-ECC-384-R1",
          ekus: [Ca::EKUS[:code_signing]],
          end_entity: Ca::END_ENTITY[:evcs]
      )
      Ca.find_or_initialize_by(ref: "0032").update_attributes(
          friendly_name: "SSL.com Basic Email RSA",
          profile_name: "MYSSL_EAV_RSA_SMIME_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-RSA-4096-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_EAV_CERT_EE"
      )
      Ca.find_or_initialize_by(ref: "0033").update_attributes(
          friendly_name: "SSL.com MySSL Pro RSA",
          profile_name: "MYSSL_IV_RSA_SMIME_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-RSA-4096-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_IV_CERT_EE"
      )
      Ca.find_or_initialize_by(ref: "0034").update_attributes(
          friendly_name: "SSL.com Basic Email ECC",
          profile_name: "MYSSL_EAV_ECC_SMIME_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-ECC-384-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_EAV_CERT_EE"
      )
      Ca.find_or_initialize_by(ref: "0035").update_attributes(
          friendly_name: "SSL.com MySSL Pro ECC",
          profile_name: "MYSSL_IV_ECC_SMIME_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-ECC-384-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_IV_CERT_EE"
      )
      Ca.find_or_initialize_by(ref: "0036").update_attributes(
          friendly_name: "SSL.com Business Identity RSA",
          profile_name: "MYSSL_OV_RSA_SMIME_DOCSIGNING_CERT",
          algorithm: "rsa",
          size: 4096,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-RSA-4096-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_OV_CERT_EE"
      )
      Ca.find_or_initialize_by(ref: "0037").update_attributes(
          friendly_name: "SSL.com Business Identity ECC",
          profile_name: "MYSSL_OV_ECC_SMIME_DOCSIGNING_CERT",
          algorithm: "ecc",
          size: 384,
          description: Ca::SSLCOM_CA,
          type: "SubCa",
          caa_issuers: ["ssl.com"],
          host: "https://#{url}:8443/restapi",
          admin_host: "https://#{url}:8443",
          ca_name: "SSLcom-SubCA-clientCert-ECC-384-R2",
          ekus: [Ca::EKUS[:client]],
          end_entity: "MYSSL_OV_CERT_EE"
      )
      # # Dev ejbca mappings
      # Ca.find_or_initialize_by(ref: "0013d").update_attributes(
      #     friendly_name: "SSL.com CS RSA 4096 (dev)",
      #     profile_name: "RSA_CS_ULMT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-CodeSigning-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:code_signing]],
      #     end_entity: Ca::END_ENTITY[:cs]
      # )
      # Ca.find_or_initialize_by(ref: "0014d").update_attributes(
      #     friendly_name: "SSL.com EV CS RSA 4096 R2 (dev)",
      #     profile_name: "EV_RSA_CS_ULMT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-EV-CodeSigning-RSA-4096-R3",
      #     ekus: [Ca::EKUS[:code_signing]],
      #     end_entity: Ca::END_ENTITY[:evcs]
      # )
      # Ca.find_or_initialize_by(ref: "0015d").update_attributes(
      #     friendly_name: "SSL.com SSL RSA 4096 R2 (EV) (dev)",
      #     profile_name: "EV_RSA_SERVER_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-EV-SSL-RSA-4096-R3",
      #     ekus: [Ca::EKUS[:server]],
      #     end_entity: Ca::END_ENTITY[:evssl]
      # )
      # Ca.find_or_initialize_by(ref: "0016d").update_attributes(
      #     friendly_name: "SSL.com EV TimeStamping RSA 4096 (dev)",
      #     profile_name: "SSLcom-SubCA-EV-TimeStamping-RSA-4096-R1",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: Ca::SSLCOM_CA,
      #     ekus: [Ca::EKUS[:time_stamping]]
      # )
      # Ca.find_or_initialize_by(ref: "0017d").update_attributes(
      #     friendly_name: "SSL.com SSL RSA 4096 (DV) (dev)",
      #     profile_name: "DV_RSA_SERVER_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:server]],
      #     end_entity: Ca::END_ENTITY[:dvssl]
      # )
      # Ca.find_or_initialize_by(ref: "0018d").update_attributes(
      #     friendly_name: "SSL.com SSL RSA 4096 (OV) (dev)",
      #     profile_name: "OV_RSA_SERVER_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-SSL-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:server]],
      #     end_entity: Ca::END_ENTITY[:ovssl]
      # )
      # Ca.find_or_initialize_by(ref: "0020d").update_attributes(
      #     friendly_name: "SSLcomEVRSASSLsubCA (dev)",
      #     profile_name: "EV_RSA_SERVER_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcomEVRSASSLsubCA",
      #     ekus: [Ca::EKUS[:server]],
      #     end_entity: Ca::END_ENTITY[:evssl]
      # )
      # Ca.find_or_initialize_by(ref: "0021d").update_attributes(
      #     friendly_name: "NAESB Client Cert Rudimentary Assurance (dev)",
      #     profile_name: "RSA_NAESB_RA_CLIENT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:client]],
      #     end_entity: Ca::END_ENTITY[:ov_client]
      # )
      # Ca.find_or_initialize_by(ref: "0022d").update_attributes(
      #     friendly_name: "NAESB Client Cert Basic Assurance (dev)",
      #     profile_name: "RSA_NAESB_BA_CLIENT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:client]],
      #     end_entity: Ca::END_ENTITY[:ov_client]
      # )
      # Ca.find_or_initialize_by(ref: "0023d").update_attributes(
      #     friendly_name: "NAESB RSA Client Cert High Assurance (dev)",
      #     profile_name: "RSA_NAESB_HA_CLIENT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:client]],
      #     end_entity: Ca::END_ENTITY[:ov_client]
      # )
      # Ca.find_or_initialize_by(ref: "0024d").update_attributes(
      #     friendly_name: "NAESB RSA Client Cert Medium Assurance (dev)",
      #     profile_name: "RSA_NAESB_MA_CLIENT_CERT",
      #     algorithm: "rsa",
      #     size: 4096,
      #     description: Ca::SSLCOM_CA,
      #     type: "SubCa",
      #     caa_issuers: ["ssl.com"],
      #     host: "https://#{shadow_url}:8443/restapi",
      #     admin_host: "https://#{shadow_url}:8443",
      #     ca_name: "SSLcom-SubCA-NAESB-clientAuth-RSA-4096-R1",
      #     ekus: [Ca::EKUS[:client]],
      #     end_entity: Ca::END_ENTITY[:ov_client]
      # )
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
    end
    live=([]).tap do |certificates|
      if ENV['LIVE']
        if ENV['LIVE'] == "all"
          certificates << Certificate.all.to_a
        else
          ENV['LIVE'].split(",").each do |prod_root|
            certificates << Certificate.where{product =~ "%#{prod_root}%"}.all.to_a
          end
        end
      end
    end.flatten
    cas_certificates = ->(ca,cert,ssl_account_id=nil){
      next if default and ca.host and !ca.host.include?(default)
      status = (ca.host and default and ca.host.include?(default)) ? :default : ca.ref=~/d\Z/ ? :shadow : :active
      unless ca.is_a?(EndEntityProfile) or ca.is_a?(RootCa) or ca.ekus.blank?
        if cert.is_evcs? and ca.end_entity==(Ca::END_ENTITY[:evcs])
          cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
            status: CasCertificate::STATUS[(ca.ref=="0014" and live.include?(cert) and default.blank?) ? :default : status],
                                       ssl_account_id: ssl_account_id)
        elsif cert.is_cs? and ca.end_entity==(Ca::END_ENTITY[:cs])
          cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
            status: CasCertificate::STATUS[(ca.ref=="0013" and live.include?(cert) and default.blank?) ? :default : status],
                                       ssl_account_id: ssl_account_id)
        elsif cert.product=~/naesb-basic/
            cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
              status: CasCertificate::STATUS[(ca.ref=="0022" and live.include?(cert) and default.blank?) ? :default : status],
                                         ssl_account_id: ssl_account_id)
        elsif cert.is_client_basic?
          cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
            status: CasCertificate::STATUS[(ca.ref=="0032" and live.include?(cert) and default.blank?) ? :default : status],
                                       ssl_account_id: ssl_account_id)
        elsif cert.is_client_pro?
          cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
            status: CasCertificate::STATUS[(ca.ref=="0033" and live.include?(cert) and default.blank?) ? :default : status],
                                       ssl_account_id: ssl_account_id)
        elsif cert.is_client_business?
          cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
            status: CasCertificate::STATUS[(ca.ref=="0036" and live.include?(cert) and default.blank?) ? :default : status],
                                       ssl_account_id: ssl_account_id)
          elsif cert.is_server? and (cert.is_dv? or cert.is_ov? or cert.is_ev?)
          if ca.end_entity==(Ca::END_ENTITY[:dvssl])
            cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
              status: CasCertificate::STATUS[(ca.ref=="0017" and live.include?(cert) and cert.is_dv? and default.blank?) ? :default : status],
                                         ssl_account_id: ssl_account_id)
          elsif (cert.is_ov? or cert.is_ev?) and ca.end_entity==(Ca::END_ENTITY[:ovssl])
            unless ENV["SHADOW"]=="DV" and status==:shadow
              cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
                status: CasCertificate::STATUS[(ca.ref=="0018" and live.include?(cert) and cert.is_ov? and default.blank?) ? :default : status],
                                           ssl_account_id: ssl_account_id)
            end
          elsif cert.is_ev? and ca.end_entity==(Ca::END_ENTITY[:evssl])
            unless ENV["SHADOW"]=="DV" and status==:shadow
              cert.cas_certificates.find_or_initialize_by(ca_id: ca.id).update_attributes(
                 status: CasCertificate::STATUS[(ca.ref=="0015" and live.include?(cert) and default.blank?) ? :default : status],
                 ssl_account_id: ssl_account_id)
            end
          end
        end
      end
    }
    if ENV['SSL_ACCOUNT_IDS']
      ENV['SSL_ACCOUNT_IDS'].split(',').each do |ssl_account_id|
        SslAccount.find(ssl_account_id.to_i).cas_certificates.delete_all
      end
    elsif ENV['RESET']=="true"
      CasCertificate.delete_all
    end
    live.each {|cert|
      Ca.all.each {|ca|
        if ENV['SSL_ACCOUNT_IDS']
          ENV['SSL_ACCOUNT_IDS'].split(',').each do |ssl_account_id|
            cas_certificates.call(ca,cert,ssl_account_id.to_i)
          end
        else
          cas_certificates.call(ca,cert)
        end
      }
    }
    Rails.cache.fetch(CasCertificate::GENERAL_DEFAULT_CACHE) do
      CasCertificate.general.default.any?{|cc|cc.certificate.is_server?}
    end
  end

  desc "Change the ip address of the host for failover"
  # EJBCA_ENV - Which EJBCA mappings do we want to change?
  # HOST - To which host or ip address do we want to change to?
  # REVERT - Revert to the original settings based on environment (EJBCA-ENV)?

  task change_host: :environment do
    ip_address=
        case ENV['EJBCA_ENV']
        when "production"
          SslcomCaApi::PRODUCTION_IP
        when "staging"
          SslcomCaApi::STAGING_IP
        when "development"
          SslcomCaApi::DEVELOPMENT_IP
        end
    if ENV['REVERT']
      Ca.where{host=~"%#{ENV['HOST']}%"}.each{|ca|
        ca.update_columns(host: ca.host.gsub(ENV['HOST'],ip_address),
                          admin_host: ca.admin_host.gsub(ENV['HOST'],ip_address))}
    else
      Ca.where{host=~"%#{ip_address}%"}.each{|ca|
        ca.update_columns(host: ca.host.gsub(ip_address,ENV['HOST']),
                          admin_host: ca.admin_host.gsub(ip_address,ENV['HOST']))}
    end if ENV['HOST']
  end
end
