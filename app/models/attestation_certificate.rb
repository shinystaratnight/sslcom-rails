class AttestationCertificate < SignedCertificate
  belongs_to :certificate_content

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || certificate_content.ref).gsub('*', 'STAR').gsub('.', '_')
  end

  def zipped_amazon_bundle(is_windows = false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = certificate_content.certificate_order
    path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file = File.new(ca_bundle(is_windows: is_windows, server: "amazon"), "r")
      zos.get_output_stream(AMAZON_BUNDLE) {|f|f.puts (is_windows ?
                                                           file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def create_attestation_cert_zip_bundle(options={})
    options[:is_windows] = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = certificate_content.certificate_order
    path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      if certificate_content.ca
        x509_certificates.drop(1).each do |x509_cert|
          zos.get_output_stream((x509_cert.subject.common_name || x509_cert.serial.to_s).
              gsub(/[\s\.\*\(\)]/,"_").upcase+'.crt') {|f|
            f.puts (options[:is_windows] ? x509_cert.to_s.gsub(/\n/, "\r\n") : x509_cert.to_s)
          }
        end
      else
        co.bundled_cert_names(components: true).each do |file_name|
          file = File.new(co.bundled_cert_dir + file_name.strip, "r")
          zos.get_output_stream(file_name.strip) {|f|
            f.puts (options[:is_windows] ? file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
        end
      end
      cert = options[:is_windows] ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def friendly_common_name
    (common_name || serial).gsub('*', 'STAR').gsub('.', '_')
  end

  def ejbca_username
    read_attribute(:ejbca_username) or (certificate_content.blank? ? nil : certificate_content.sslcom_ca_requests.first.try(:username))
  end

  def self.attestation_pass?(attest_cert, attest_issuer_cert)
    verified = verify_signature(attest_issuer_cert.strip, attest_cert.strip)

    if verified
      root_cert_label=false
      AttestationCertificate::ATTESTATION_ROOT_CERTIFICATES.each do |root_cert|
        verified = verify_signature(root_cert.strip, attest_issuer_cert.strip)

        if verified
          root_cert_label={cn: OpenSSL::X509::Certificate.new(root_cert.strip).subject.to_s}
          break
        end
      end
    end

    return root_cert_label
  end

  def self.verify_signature(parent, child)
    cert_body = SignedCertificate.enclose_with_tags(child)
    begin
      child_cert = OpenSSL::X509::Certificate.new(cert_body)
    rescue Exception => ex
      logger.error ex
      return false
    end

    cert_body = SignedCertificate.enclose_with_tags(parent)
    begin
      parent_cert = OpenSSL::X509::Certificate.new(cert_body)
    rescue Exception => ex
      logger.error ex
      return false
    end

    return child_cert.verify(parent_cert.public_key)
  end

  YUBIKEY_PIV_ROOT_CA="-----BEGIN CERTIFICATE-----
MIIDFzCCAf+gAwIBAgIDBAZHMA0GCSqGSIb3DQEBCwUAMCsxKTAnBgNVBAMMIFl1
YmljbyBQSVYgUm9vdCBDQSBTZXJpYWwgMjYzNzUxMCAXDTE2MDMxNDAwMDAwMFoY
DzIwNTIwNDE3MDAwMDAwWjArMSkwJwYDVQQDDCBZdWJpY28gUElWIFJvb3QgQ0Eg
U2VyaWFsIDI2Mzc1MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMN2
cMTNR6YCdcTFRxuPy31PabRn5m6pJ+nSE0HRWpoaM8fc8wHC+Tmb98jmNvhWNE2E
ilU85uYKfEFP9d6Q2GmytqBnxZsAa3KqZiCCx2LwQ4iYEOb1llgotVr/whEpdVOq
joU0P5e1j1y7OfwOvky/+AXIN/9Xp0VFlYRk2tQ9GcdYKDmqU+db9iKwpAzid4oH
BVLIhmD3pvkWaRA2H3DA9t7H/HNq5v3OiO1jyLZeKqZoMbPObrxqDg+9fOdShzgf
wCqgT3XVmTeiwvBSTctyi9mHQfYd2DwkaqxRnLbNVyK9zl+DzjSGp9IhVPiVtGet
X02dxhQnGS7K6BO0Qe8CAwEAAaNCMEAwHQYDVR0OBBYEFMpfyvLEojGc6SJf8ez0
1d8Cv4O/MA8GA1UdEwQIMAYBAf8CAQEwDgYDVR0PAQH/BAQDAgEGMA0GCSqGSIb3
DQEBCwUAA4IBAQBc7Ih8Bc1fkC+FyN1fhjWioBCMr3vjneh7MLbA6kSoyWF70N3s
XhbXvT4eRh0hvxqvMZNjPU/VlRn6gLVtoEikDLrYFXN6Hh6Wmyy1GTnspnOvMvz2
lLKuym9KYdYLDgnj3BeAvzIhVzzYSeU77/Cupofj093OuAswW0jYvXsGTyix6B3d
bW5yWvyS9zNXaqGaUmP3U9/b6DlHdDogMLu3VLpBB9bm5bjaKWWJYgWltCVgUbFq
Fqyi4+JE014cSgR57Jcu3dZiehB6UtAPgad9L5cNvua/IWRmm+ANy3O2LH++Pyl8
SREzU8onbBsjMg9QDiSf5oJLKvd/Ren+zGY7
-----END CERTIFICATE-----"

  YUBIKEY_U2F_457200631="-----BEGIN CERTIFICATE-----
MIIDHjCCAgagAwIBAgIEG0BT9zANBgkqhkiG9w0BAQsFADAuMSwwKgYDVQQDEyNZ
dWJpY28gVTJGIFJvb3QgQ0EgU2VyaWFsIDQ1NzIwMDYzMTAgFw0xNDA4MDEwMDAw
MDBaGA8yMDUwMDkwNDAwMDAwMFowLjEsMCoGA1UEAxMjWXViaWNvIFUyRiBSb290
IENBIFNlcmlhbCA0NTcyMDA2MzEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC/jwYuhBVlqaiYWEMsrWFisgJ+PtM91eSrpI4TK7U53mwCIawSDHy8vUmk
5N2KAj9abvT9NP5SMS1hQi3usxoYGonXQgfO6ZXyUA9a+KAkqdFnBnlyugSeCOep
8EdZFfsaRFtMjkwz5Gcz2Py4vIYvCdMHPtwaz0bVuzneueIEz6TnQjE63Rdt2zbw
nebwTG5ZybeWSwbzy+BJ34ZHcUhPAY89yJQXuE0IzMZFcEBbPNRbWECRKgjq//qT
9nmDOFVlSRCt2wiqPSzluwn+v+suQEBsUjTGMEd25tKXXTkNW21wIWbxeSyUoTXw
LvGS6xlwQSgNpk2qXYwf8iXg7VWZAgMBAAGjQjBAMB0GA1UdDgQWBBQgIvz0bNGJ
hjgpToksyKpP9xv9oDAPBgNVHRMECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBBjAN
BgkqhkiG9w0BAQsFAAOCAQEAjvjuOMDSa+JXFCLyBKsycXtBVZsJ4Ue3LbaEsPY4
MYN/hIQ5ZM5p7EjfcnMG4CtYkNsfNHc0AhBLdq45rnT87q/6O3vUEtNMafbhU6kt
hX7Y+9XFN9NpmYxr+ekVY5xOxi8h9JDIgoMP4VB1uS0aunL1IGqrNooL9mmFnL2k
LVVee6/VR6C5+KSTCMCWppMuJIZII2v9o4dkoZ8Y7QRjQlLfYzd3qGtKbw7xaF1U
sG/5xUb/Btwb2X2g4InpiB/yt/3CpQXpiWX/K4mBvUKiGn05ZsqeY1gx4g0xLBqc
U9psmyPzK+Vsgw2jeRQ5JlKDyqE0hebfC1tvFu0CCrJFcw==
-----END CERTIFICATE-----"

  SAFENET_LUNA_ROOT_CA = "-----BEGIN CERTIFICATE-----
MIIFbjCCA1agAwIBAgIHAIBFAAAABzANBgkqhkiG9w0BAQUFADBqMQswCQYDVQQG
EwJDQTEQMA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0YXdhMRswGQYDVQQK
ExJDaHJ5c2FsaXMtSVRTIEluYy4xGzAZBgNVBAMTEkNocnlzYWxpcy1JVFMgUm9v
dDAeFw0wMjAxMDEwMDAwMDBaFw0zMjAxMDEwMDAwMDBaMGoxCzAJBgNVBAYTAkNB
MRAwDgYDVQQIEwdPbnRhcmlvMQ8wDQYDVQQHEwZPdHRhd2ExGzAZBgNVBAoTEkNo
cnlzYWxpcy1JVFMgSW5jLjEbMBkGA1UEAxMSQ2hyeXNhbGlzLUlUUyBSb290MIIC
IDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAumAZOCcEhuMbWkao2zkD9Qud
/JwNsFmeobZeOlcRVP1WxknrabsFadaYQwy7lntDPaiVWwzXXsBm+CemB6AlFZxc
IRVy7tIydQGHCY5mOeHTRTO/HS1JEbwZaNXc7U6dhtnjjWrJlzNDHQO/QAxMGvRs
0rXJerwm13iQ5uJHolMjA6DSQH6dM2gA3KF8Zkd+K3okfGZS6z7J9ZmbCE98av7h
foZIY/xKl5GK4qqgJLaArEpqsjyZ5m6SAG0HrIWfWnpNfb/vLJxusWGTKi99f69N
O4goHC7toGHDNeax+Wdtogfupk+WHSWDswFOzmK8uEFWXjbcRpolAapwZJBbNviD
CdXflOo4Ad43t4gGLkMuTeG/9zIHV9wcM66oabZGSAvOrrpDGQR8OB+zZVsssfxs
GloEVuO+qLTEq+6cgo656MKEwCcw9yffeJEWdpL+aQbI5HNkHeo6n5WnySKd8MHW
LzRfj2hoIdEAXhyiF3zz4kSfYsRJPVdC5ulRZ89nWKYTRs6DrwF14XMfMayL9r+e
RXjk/yeyklwsfznFiLOVnoXsKXJUY8apfIpxCZL6bLJD4IXgQ2ghkwje/5hotMP3
5QAPgBX64sLy/EuuU4+mLjZQztiaaDoB3tPW3cA3KyPX9wUl1ysDUALTZJEicI4j
UptorrcUmoAFLHUbCWkCAQOjGzAZMBcGA1UdJQEB/wQNMAsGCSsGAQQB4F8BATAN
BgkqhkiG9w0BAQUFAAOCAgEAGSzexgqzz1P7UZqDALidbo0One+GoUeYmaks68+S
DRqEkSV5QpRAFflnL9dK68fCIKzl4SeossJlLy+I22NjZ+xLtXvNpaiL7/M6JPyH
E0DwhFQdNumj7j/7uBro2wVHUTy29bm4DCezxqxx+978SJx0vyzcW9mYwzyqd8gr
uJmSUC8DR82bPHQj8XXS1R1yOvwbyo3qRpiLphoUtzOMVL86NMzEV7Sjd7Y1wGKz
dLqFgbEfhUaS2CvR/SRNPpo+3Vvf/gsUgCatP72zrZtjENcJ7u9d2DER7AAP3Rdb
hfZDoHMAMm9P7RIL9rsctSOm2ux7wXr4xqoDZ/eIiZwoUAevf9oQpIC24dvk7Ltv
K+GvKy52JmnO3YSMBDNKl/lbPTaYrZ1SDficexV3P4i9dC1utvZV0FL7zqJdVWkw
JVjFbdg7gYlsq+qQ6hNPLuzS4SAmPSSJzebjO3awK8RpdJ+FaC3EzQebC3Mbzfun
njrPJsrL65xBDhmS84S2UGYJPaoU7jMAUMeUgJJSMeDTIO25l0UWQvA4fAgfXTZT
5Q0HzMfuXjSKKeT+qHWLy8lizScxMWU3nK4lWVnL//Iungn5q9CzuHHXP/MDwDit
exNoPYM/FRrvp9oQybzK2VihJGfa83KwvJjHaEvaGOU8Yg2k1cirvlTznE5nLNcW
xm4=
-----END CERTIFICATE-----"

  ATTESTATION_ROOT_CERTIFICATES=[YUBIKEY_PIV_ROOT_CA,YUBIKEY_U2F_457200631,SAFENET_LUNA_ROOT_CA]
end