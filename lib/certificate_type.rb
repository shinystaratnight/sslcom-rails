module CertificateType

  def is_dv?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_DV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_ov?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_OV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :
           self).product =~ /\A(wildcard|high_assurance|ucc|premiumssl)/ ||
          is_client_enterprise? || is_client_business? || is_client_pro?
    end
  end
  
  def is_ev?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_EV))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Aev(?!\-code)/
    end
  end

  def is_iv?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_IV))
    else
      # (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_evcs?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_EVCS))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Aev-code-signing/
    end
  end

  # implies non EV
  def is_cs?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_CS))
    else
      (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(code[_\-]signing)/
    end
  end

  # this covers both ev and non ev code signing
  def is_code_signing?
    is_cs? or is_evcs?
  end

  def is_test_certificate?
    if self.is_a? SignedCertificate
      !!(decoded.include?(SignedCertificate::OID_TEST))
    else
      # (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\A(basic|free)/
    end
  end

  def is_smime?
    # (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product =~ /\Asmime/
    is_client?
  end

  def is_client?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product.include?('personal')
  end

  def is_smime_or_client?
    is_smime? || is_client? || is_naesb?
  end

  def is_csr_last_step?
    is_smime_or_client? || is_code_signing?
  end

  def is_time_stamping?
    false
  end

  def is_naesb?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product.include?('naesb')
  end

  def is_client_basic?
    is_client? and !is_naesb? and
        (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/personal.*?basic\z/
  end

  def is_client_pro?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/personal.*?pro\z/
  end

  def is_client_business?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/personal.*?business\z/
  end

  def is_client_enterprise?
    (self.is_a?(ApiCertificateRequest) ? target_certificate :  self).product_root=~/personal.*?enterprise\z/
  end

  def is_ov_client?
    is_client_enterprise? or is_client_business?
  end

  def is_document_signing?
    is_client_pro? || is_client_business? || is_client_enterprise?
  end

  def requires_company_info?
    is_client_business? ||
    is_client_enterprise? ||
    is_server? ||
    is_code_signing? ||
    is_ov? ||
    is_naesb?
  end

  def requires_locked_registrant?
    is_code_signing? ||
    is_ov? ||
    is_ev? ||
    is_client_business? ||
    is_client_enterprise? ||
    is_naesb?
  end

  def comodo_ca_id
    if is_ev?
      Settings.ca_certificate_id_ev
    elsif is_ov?
      Settings.ca_certificate_id_ov
    else
      Settings.ca_certificate_id_dv
    end
  end

  def client_smime_validations
    if is_ov_client? || is_naesb?
      'iv_ov'
    elsif is_client_pro?
      'iv'
    else
      'none'
    end
  end

  def validation_type
    if is_dv?
      "dv"
    elsif is_cs?
      "cs"
    elsif is_evcs?
      "evcs"
    elsif is_ev?
      "ev"
    elsif is_ov?
      "ov"
    elsif is_smime_or_client?
      "iv"
    end
  end

  SSLCOM_RSA_ROOT=<<-EOS
MIIF3TCCA8WgAwIBAgIIeyyb0xaAMpkwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UE
BhMCVVMxDjAMBgNVBAgMBVRleGFzMRAwDgYDVQQHDAdIb3VzdG9uMRgwFgYDVQQK
DA9TU0wgQ29ycG9yYXRpb24xMTAvBgNVBAMMKFNTTC5jb20gUm9vdCBDZXJ0aWZp
Y2F0aW9uIEF1dGhvcml0eSBSU0EwHhcNMTYwMjEyMTczOTM5WhcNNDEwMjEyMTcz
OTM5WjB8MQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMxEDAOBgNVBAcMB0hv
dXN0b24xGDAWBgNVBAoMD1NTTCBDb3Jwb3JhdGlvbjExMC8GA1UEAwwoU1NMLmNv
bSBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IFJTQTCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBAPkP3aMrfcvQKv7sZ4Wm5y4bunfh4/WvpOz6Sl2R
xFdHaxh3a3by/ZPkPQ/CFp4LZsNWlJ4Xg4XOVu/yFv0AYvUiCVToZRdOQbngT0aX
qhvIuG5iXmmxX9sqAn78bMrzQdjt0Oj8P2FI7bADFB0QDksZ4LtO7IZl/zbzXmcC
C52GVWH9ejjt/uIZALdvoVBidXQ8oPrIJZK0bnoix/geoeOy3ZExqysdBP+lSgQ3
6YWkMyv94tZVNHwZpEpox7Ko07fKoZOI68GXvIz5HdkihCR0xwQ9aqkpk8zruFvh
/l8lqjRYyMEjVJ0bmBHDOJx+PYZspQ9AhnwC9FwCTyjLrnGfDzrIM/4RJTXq/LrF
YD3ZfBjVsqnTdXgDciLKOsMf7yzlLqn6niy2UUb9rwPW6mBo6oUWNmuF6R7As93E
JNyAKoFBbZQ+yODJgUEAnl6/f8UImKIYLEJAs/lvOCdLToD0PYFH4Ih86hzOtXVc
US4cK38acijnALXRdMbX5J+tB5O2UzU1/Dfkw/ZdFr4hc96SCvigY2q8lpJqPvi8
ZVWb3vUNiSYE/CUapiVpy8JtynziWV+XrOvvLsi81xtZPCvM8hnIk2snYxnP/Okm
+Mpxm3+T/jRnhE6Z6/yzeAkzcLpmpnbtG3PrGqUNxCITIJRWCk4sbE6x/c+cCbqi
M+2HAgMBAAGjYzBhMB0GA1UdDgQWBBTdBAkHovV6fVJTEpKV7jiAJQ2mWTAPBgNV
HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFN0ECQei9Xp9UlMSkpXuOIAlDaZZMA4G
A1UdDwEB/wQEAwIBhjANBgkqhkiG9w0BAQsFAAOCAgEAIBgRlCn7Jp0cHh5wYfGV
cpNxJK1ok1iOMq8bs3AD/CUrdIWQPXhq9LmLpZc7tRiRux6n+UBbkflVma8eEdBc
Hadm47GUBwwyOabqG7B52B2ccETjit3E+ZUfijhDPwGFpUenPUayvOUiaPd7nNgs
PgohyC0zrL/FgZkxdMF1ccW+sfAjRfSda/wZY52jvATGGAslu1OJD7OAUN5F7kR/
q5R4ZJjT9ijdh9hwZXT7DrkT66cPYakylszeu+1jTBi7qUD3oFRuIIhxdRjqerQ0
cuAjJ3dctpDqhiVAq+8zD8ufgr6iIPv2tS0a5sKFsXQP+8hlAqRSAUfdSSLBv9jr
a6x+3uxjMxW3IwiPxg+NQVrdjsW5j+VFP3jbutIbQLH+cU0/4IGiul607BXgk90I
H37hVZkLId6Tngr75qNJvTYw/ud3sqB1l7UtgYgXZSD32pAAn8lSzDLKNXz1PQ/Y
K9f1JmzJBjSWFupwWRoyeXkLtoh/D1JIPb9s2KJELtFOt3JY04kTlf5Eq/jXixtu
nLwsoFvVagCvXzfh1foQC5ichucmj87w7G6KVwuA406ywKBjYZC6VWg3dGq2ktuf
oYYitmUnDuy2n0Jg5GfCtdpBC8TTi2EbvPofkSvXRAdeuims2cXp71NIWuuA8ShY
Ic2wBlX7Jz9TkHCpBB5XJ7k=
  EOS


  SSLCOM_EV_RSA_ROOT_R2=<<-EOS
MIIF6zCCA9OgAwIBAgIIVrYpzTS8ePYwDQYJKoZIhvcNAQELBQAwgYIxCzAJBgNV
BAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjEYMBYGA1UE
CgwPU1NMIENvcnBvcmF0aW9uMTcwNQYDVQQDDC5TU0wuY29tIEVWIFJvb3QgQ2Vy
dGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBIFIyMB4XDTE3MDUzMTE4MTQzN1oXDTQy
MDUzMDE4MTQzN1owgYIxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4G
A1UEBwwHSG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTcwNQYDVQQD
DC5TU0wuY29tIEVWIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBIFIy
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjzZlQOHWTcDXtOlG2mvq
M0fNTPl9fb69LT3w23jhhqXZuglXaO1XPqDQCEGD5yhBJB/jchXQARr7XnAjssuf
OePPxU7Gkm0mxnu7s9onnQqG6YE3Bf7wcXHswxzpY6IXFJ3vG2fThVUCAtZJycxa
4bH3bzKfydQ7iEGonL3Lq9ttewkfokxykNorCPzPPFTOZw+oz12WGQvE43LrrdF9
HSfvkusQv1vrO6/PgN3B0pYEW3p+pKk8OHakYo6gOV7qd89dAFmPZiw+B6KjBSYR
aZfqhbcPlgtLyEDhULouisv3D5oi53+aNxPN8k0TayHRwMwi8qFG9kRpnMphNQcA
b9ZhCBHqurj26bNg5U257J8UZslXWNvNh2n4ioYSA0e/ZhN2rHd9NCSFg83XqpyQ
Gp8hLH94t2S42Oim9HizVcuE0jLEeK6jj2HdzghTreyI/BXkmg3mnxp3zkyPuBQV
PWKchjgGAGYS5Fl2WlPAApiiECtoRHuOec4zSnaqW4EWG7WK2NAAe15itAnWhmMO
pgWVSbooi4iTsjQc2KRVbrcc0N6ZVTsj9CLg+SlmJuwgUHfbSguPvuUCYHBBXtSu
UDkiFCbLsjtzdFVHB3mBOagwE0TlBIqulhMlQg+5U8Sb/M3kHN48+qvWBkofZ6aY
MBzdLNvcGJVXZsb/XItW9XcCAwEAAaNjMGEwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
HSMEGDAWgBT5YLvU49U09rj1BoAlp3PbRmmonjAdBgNVHQ4EFgQU+WC71OPVNPa4
9QaAJadz20ZpqJ4wDgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3DQEBCwUAA4ICAQBW
s47LCp1Jjr+kxJG7ZhcFUZh1++VQLHqe8RT6q9OKPv+RKY9ji9i0qVQBDb6Thi/5
Sm3HXvVX+cpVHBK+Rw82xd9qt9t1wkclf7nxY/hoLVUE0fKNsKTPvDxeH3jnpaAg
cLAExbf3cqfeIg29MyVGjGSSJuM+LmOW2puMPfgYCdcDzH2GguDKBAdRUNf/ktUM
79qGn5nX67evaOI5JpS6aLe/g9Pqemc9YmeuJeVy6OLk7K4S9ksrPJ/psEDzOFSz
/bdoyNrGj1E8svuR3Bznm53htw1yj+KkxKl4+esUrMZDBcJlOSgYAsOCsp0FvmXt
ll9ldDz7CTUue5wT/RsPXcdtgTpWD8w74a8CLyKsRspGPKAcTNZEtF4uXBVmCeEm
Kf7GUmG6sXP/wwyc5WxqlD8UykAWlYTzWamsX0xhk23RO8yilQwipmdnRC652dKK
QbNmC1r7fSOl8hqw/96bg5Qu0T/fkreRrwU7ZcegbLHNYhLDkBvjJc40vG93drEQ
w/cFGsDWr3RiSBd3kmmQYRzelYB0VI8YHMPzA9C/pEN1hlMYegouCRw2n5H9gooi
S9EOUCXdywMMF8mDAAhONU2Ki+3wApRmLER/y5UnlhetCTCstnEXbosX9hwJ1C07
mKVx01QT2WDz9UtmT/rx7iASjbSsV7FFY6GsdqnC+w==
  EOS

  CERTUM_XSIGN_EV = <<-EOS
MIIF3jCCBMagAwIBAgIQYvgSo19SvXS3GNYQrEtHgzANBgkqhkiG9w0BAQsFADB+
MQswCQYDVQQGEwJQTDEiMCAGA1UEChMZVW5pemV0byBUZWNobm9sb2dpZXMgUy5B
LjEnMCUGA1UECxMeQ2VydHVtIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MSIwIAYD
VQQDExlDZXJ0dW0gVHJ1c3RlZCBOZXR3b3JrIENBMB4XDTE4MDkxMTA5MjgyMFoX
DTIzMDkxMTA5MjgyMFowgYIxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQ
MA4GA1UEBwwHSG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTcwNQYD
VQQDDC5TU0wuY29tIEVWIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgUlNB
IFIyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjzZlQOHWTcDXtOlG
2mvqM0fNTPl9fb69LT3w23jhhqXZuglXaO1XPqDQCEGD5yhBJB/jchXQARr7XnAj
ssufOePPxU7Gkm0mxnu7s9onnQqG6YE3Bf7wcXHswxzpY6IXFJ3vG2fThVUCAtZJ
ycxa4bH3bzKfydQ7iEGonL3Lq9ttewkfokxykNorCPzPPFTOZw+oz12WGQvE43Lr
rdF9HSfvkusQv1vrO6/PgN3B0pYEW3p+pKk8OHakYo6gOV7qd89dAFmPZiw+B6Kj
BSYRaZfqhbcPlgtLyEDhULouisv3D5oi53+aNxPN8k0TayHRwMwi8qFG9kRpnMph
NQcAb9ZhCBHqurj26bNg5U257J8UZslXWNvNh2n4ioYSA0e/ZhN2rHd9NCSFg83X
qpyQGp8hLH94t2S42Oim9HizVcuE0jLEeK6jj2HdzghTreyI/BXkmg3mnxp3zkyP
uBQVPWKchjgGAGYS5Fl2WlPAApiiECtoRHuOec4zSnaqW4EWG7WK2NAAe15itAnW
hmMOpgWVSbooi4iTsjQc2KRVbrcc0N6ZVTsj9CLg+SlmJuwgUHfbSguPvuUCYHBB
XtSuUDkiFCbLsjtzdFVHB3mBOagwE0TlBIqulhMlQg+5U8Sb/M3kHN48+qvWBkof
Z6aYMBzdLNvcGJVXZsb/XItW9XcCAwEAAaOCAVEwggFNMBIGA1UdEwEB/wQIMAYB
Af8CAQIwHQYDVR0OBBYEFPlgu9Tj1TT2uPUGgCWnc9tGaaieMB8GA1UdIwQYMBaA
FAh2zcsH/yT2xc3tu5C84oQ3RnX3MA4GA1UdDwEB/wQEAwIBBjA2BgNVHR8ELzAt
MCugKaAnhiVodHRwOi8vc3NsY29tLmNybC5jZXJ0dW0ucGwvY3RuY2EuY3JsMHMG
CCsGAQUFBwEBBGcwZTApBggrBgEFBQcwAYYdaHR0cDovL3NzbGNvbS5vY3NwLWNl
cnR1bS5jb20wOAYIKwYBBQUHMAKGLGh0dHA6Ly9zc2xjb20ucmVwb3NpdG9yeS5j
ZXJ0dW0ucGwvY3RuY2EuY2VyMDoGA1UdIAQzMDEwLwYEVR0gADAnMCUGCCsGAQUF
BwIBFhlodHRwczovL3d3dy5jZXJ0dW0ucGwvQ1BTMA0GCSqGSIb3DQEBCwUAA4IB
AQB3fEIlifCgb1DYzJtme4/TgnHi06tdHQmJyyzgqYqmnzfE+DBtuvHNVhalGHii
EvHuDXly28VCWb5aq4RKOkXrjuoCkSVtBf1Sys9ClK/Bqb7biO/58Ysoe6hwbikM
0lmi0c27gq2zMGi4/uZ8bzP+fpURtCHunmotpIMitYIz5nKmfLYEJALVDL/6ad8O
Lr+/dZTXKIDIYqdVjcGsvy0mQ12t+VRuJMRF+XTzy/LgDlr4SJjYZvWN7I4BxHyD
82YHj8XFnxgUiD47bn+ykoQa8WX4yV0xZeF+YN0lWLQCunFalTtqr4y6Mmc3pWBW
k5ojwldA7NjrZWoFiQ/blgLF
  EOS

  CERTUM_XSIGN=<<-EOS
MIIF2DCCBMCgAwIBAgIRAOQnBJX2jJHW0Ox7SU6k3xwwDQYJKoZIhvcNAQELBQAw
fjELMAkGA1UEBhMCUEwxIjAgBgNVBAoTGVVuaXpldG8gVGVjaG5vbG9naWVzIFMu
QS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEiMCAG
A1UEAxMZQ2VydHVtIFRydXN0ZWQgTmV0d29yayBDQTAeFw0xODA5MTEwOTI2NDda
Fw0yMzA5MTEwOTI2NDdaMHwxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQ
MA4GA1UEBwwHSG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTEwLwYD
VQQDDChTU0wuY29tIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgUlNBMIIC
IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA+Q/doyt9y9Aq/uxnhabnLhu6
d+Hj9a+k7PpKXZHEV0drGHdrdvL9k+Q9D8IWngtmw1aUnheDhc5W7/IW/QBi9SIJ
VOhlF05BueBPRpeqG8i4bmJeabFf2yoCfvxsyvNB2O3Q6Pw/YUjtsAMUHRAOSxng
u07shmX/NvNeZwILnYZVYf16OO3+4hkAt2+hUGJ1dDyg+sglkrRueiLH+B6h47Ld
kTGrKx0E/6VKBDfphaQzK/3i1lU0fBmkSmjHsqjTt8qhk4jrwZe8jPkd2SKEJHTH
BD1qqSmTzOu4W+H+XyWqNFjIwSNUnRuYEcM4nH49hmylD0CGfAL0XAJPKMuucZ8P
Osgz/hElNer8usVgPdl8GNWyqdN1eANyIso6wx/vLOUuqfqeLLZRRv2vA9bqYGjq
hRY2a4XpHsCz3cQk3IAqgUFtlD7I4MmBQQCeXr9/xQiYohgsQkCz+W84J0tOgPQ9
gUfgiHzqHM61dVxRLhwrfxpyKOcAtdF0xtfkn60Hk7ZTNTX8N+TD9l0WviFz3pIK
+KBjaryWkmo++LxlVZve9Q2JJgT8JRqmJWnLwm3KfOJZX5es6+8uyLzXG1k8K8zy
GciTaydjGc/86Sb4ynGbf5P+NGeETpnr/LN4CTNwumamdu0bc+sapQ3EIhMglFYK
TixsTrH9z5wJuqIz7YcCAwEAAaOCAVEwggFNMBIGA1UdEwEB/wQIMAYBAf8CAQIw
HQYDVR0OBBYEFN0ECQei9Xp9UlMSkpXuOIAlDaZZMB8GA1UdIwQYMBaAFAh2zcsH
/yT2xc3tu5C84oQ3RnX3MA4GA1UdDwEB/wQEAwIBBjA2BgNVHR8ELzAtMCugKaAn
hiVodHRwOi8vc3NsY29tLmNybC5jZXJ0dW0ucGwvY3RuY2EuY3JsMHMGCCsGAQUF
BwEBBGcwZTApBggrBgEFBQcwAYYdaHR0cDovL3NzbGNvbS5vY3NwLWNlcnR1bS5j
b20wOAYIKwYBBQUHMAKGLGh0dHA6Ly9zc2xjb20ucmVwb3NpdG9yeS5jZXJ0dW0u
cGwvY3RuY2EuY2VyMDoGA1UdIAQzMDEwLwYEVR0gADAnMCUGCCsGAQUFBwIBFhlo
dHRwczovL3d3dy5jZXJ0dW0ucGwvQ1BTMA0GCSqGSIb3DQEBCwUAA4IBAQAflZoj
VO6FwvPUb7npBI9Gfyz3MsCnQ6wHAO3gqUUt/Rfh7QBAyK+YrPXAGa0boJcwQGzs
W/ujk06MiWIbfPA6X6dCz1jKdWWcIky/dnuYk5wVgzOxDtxROId8lZwSaZQeAHh0
ftzABne6cC2HLNdoneO6ha1J849ktBUGg5LGl6RAk4ut8WeUtLlaZ1Q8qBvZBc/k
pPmIEgAGiCWF1F7u85NX1oH4LK739VFIq7ZiOnnb7C7yPxRWOsjZy6SiTyWo0Zur
LTAgUAcab/HxlB05g2PoH/1J0OgdRrJGgia9nJ3homhBSFFuevw1lvRU0rwrROVH
13eCpUqrX5czqyQR
  EOS

  ECDSA_CSR=<<-EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIBCDCBrwIBADAdMRswGQYDVQQDDBJ0ZXN0ZWNkc2ExLnNzbC5jb20wWTATBgcq
hkjOPQIBBggqhkjOPQMBBwNCAASvDWy6+/kTAU6/SSk4xDHYib4Wjo9tfLppnAGW
ZjNfb3sZGdtRLIVeUUyDgJ1s6MVBGpw1E6wgBlbb6gYVweJBoDAwLgYJKoZIhvcN
AQkOMSEwHzAdBgNVHREEFjAUghJ0ZXN0ZWNkc2ExLnNzbC5jb20wCgYIKoZIzj0E
AwIDSAAwRQIhAIn0OdItSX8+0xREiwsN6p+njqo35eARvkUyVgo98GnHAiBVRSAG
bn1lIK8VMmDTyhOfAf2W08g3l2j49t6bZJJGTw==
-----END CERTIFICATE REQUEST-----
  EOS

end


