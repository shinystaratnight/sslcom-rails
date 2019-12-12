require './test/support/setup_helper'

FactoryBot.define do
  factory :signed_certificate do
    common_name       {'qlikdev.ezops.com'}
    status {'issued'}
    organization_unit {['Domain Control Validated']}
    fingerprint       {"--- !ruby/object:OpenSSL::BN {}\n"}
    signature        { '1E:DC:F8:1D:A3:70:32:D8:87:DE:3C:C4:AA:27:AE:98:97:DC:9C:7D'}
    parent_cert      { false}
    strength         { 4096}
    subject_alternative_names {['qlikdev.ezops.com', 'www.qlikdev.ezops.com']}
    body {
      "-----BEGIN CERTIFICATE-----\nMIIE0zCCA7ugAwIBAgIQQhU2Tr3+VrBbOxwMiWSbzTANBgkqhkiG9w0BAQsFADBN\nMQswCQYDVQQGEwJVUzEQMA4GA1UEChMHU1NMLmNvbTEUMBIGA1UECxMLd3d3LnNz\nbC5jb20xFjAUBgNVBAMTDVNTTC5jb20gRFYgQ0EwHhcNMTcwMTAxMDAwMDAwWhcN\nMTcwNDAxMjM1O
      TU5WjBqMSEwHwYDVQQLExhEb21haW4gQ29udHJvbCBWYWxpZGF0\nZWQxLjAsBgNVBAsTJUhvc3RlZCBieSBTZWN1cmUgU29ja2V0cyBMYWJvcmF0b3Jp\nZXMxFTATBgNVBAMTDGlzdGVqbWFtLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEP\nADCCAQoCggEBAM1lLjWiP5iEPpgRkIDRrU1lhfDC27XODujLSqcbpuLr
      bRr3UTYh\n1NYXEkQEqbPkYR2s9m7tOpCEr8QSoAlVY1FCGGzVbwKWSrZrgwwy8C6t76K1yx5F\njw7WUQ4CbSpThuS3h1n3vgs9cREwadKfA4Mc7WxluQWHKkfAGleI5eMTbjA6wVAm\nks6uDXUEjbJ1Kq9wx+p99coBE2g0/epB20hPm5LGb0GvfOzyyyNAJhLXvbOCuKEj\n7+4kJcF+fMVOQVmy/OL7mUAE5BaC7qWtn
      dwH0rI9RvD1WAJq/T39wpwDZV9sO9X1\nexvDghomlrpdm8cgrLXF+4pQLpSqO2FisnUCAwEAAaOCAZAwggGMMB8GA1UdIwQY\nMBaAFEaa/fxRXnxUU1LimeOzMu+TGn9WMB0GA1UdDgQWBBTHZhooBEZA+861TUqu\no9mb+5TDQTAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHSUEFjAU\nBggrBgEFBQ
      cDAQYIKwYBBQUHAwIwSgYDVR0gBEMwQTA1BgorBgEEAYKpMAEBMCcw\nJQYIKwYBBQUHAgEWGWh0dHBzOi8vY3BzLnVzZXJ0cnVzdC5jb20wCAYGZ4EMAQIB\nMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuc3NsLmNvbS9TU0xjb21EVkNB\nXzIuY3JsMGAGCCsGAQUFBwEBBFQwUjAvBggrBgEFBQcwAoYjaHR0c
      DovL2NydC5z\nc2wuY29tL1NTTGNvbURWQ0FfMi5jcnQwHwYIKwYBBQUHMAGGE2h0dHA6Ly9vY3Nw\nLnNzbC5jb20wKQYDVR0RBCIwIIIMaXN0ZWptYW0uY29tghB3d3cuaXN0ZWptYW0u\nY29tMA0GCSqGSIb3DQEBCwUAA4IBAQCuPJrmyU2H6g0gaZeCcyXdMgNdmRzxl3Bb\nJn2tQcgEy+ub5Ema5+mXWs+A77p4zz
      1Rqqthzb1/yQog2b/295jUW4qwHff1i5F0\nZvC5UDRHYY7Oh6xa0M0vNfIElzcCjtVvlMvL6wlwbixPb3L0qFS2+3suMmMewPzC\n46QllPutdqvijgCU0zAZ8QBDhmLIFpGsBKvOJ2U16k+MydCFGjuabSsIE2UU+Q8Y\n5s0JeZ495V1Upvfi1WFC5zzqry+QlRf6tZO0W6FCggsw9ueoOr5dkNRjbg2cfSjb\nRo9tm3F
      jaRTTlpcs2IhhdOmMHctTIQIjQKgs9FB+NrvtOKgQ9C6d\n-----END CERTIFICATE-----"
    }
  end

  # trait :nonwildcard_csr do
  #   after :build do |sc|
  #     initialize_certificate_csr_keys
  #     sc.body = @nonwildcard_certificate.strip
  #   end
  # end
  #
  # trait :nonwildcard_certificate_sslcom do
  #   after :build do |sc|
  #     initialize_certificate_csr_keys
  #     sc.body = @nonwildcard_certificate_sslcom.strip
  #   end
  # end
end
