require 'rails_helper'

RSpec.describe 'SMIME', type: :feature do
  context 'when purchasing' do
    describe 'downloading certficate', js: true do
      let(:user) { create(:user, :owner) }

      xit 'shows advanced options correctly' do
        as_user(user) do
          purchase_certificate
          submit_payment_information
          process_certificate
          expect(page).to have_content 'activation link sent'
          visit "/certificate_order_token/#{validation_token}/generate_cert"
          click_on 'Show Advanced Options'
          click_on 'Hide Advanced Option'
          # Api::V1::ApiCertificateRequestsController.any_instance.stubs(:generate_certificate_v1_4).returns(certificate_result)
          # click_on 'Generate Certificate'
          # using_wait_time 10 do
          #   fill_in '.pkcs_password', with: user.password
          # end
          # click_on 'Download'
          expect(page).to have_content 'Algorithm :'
        end
      end
    end
  end

  def purchase_certificate
    click_on 'BUY'
    visit '/certificates/personal-basic/buy'
    find('.submit_csr_img_tag').click
    find('img[alt="Checkout"]').click
    find('.order_next').click
  end

  def process_certificate
    click_on 'Click here'
    fill_in 'first_name', with: user[:first_name]
    fill_in 'last_name', with: user[:last_name]
    fill_in 'email', with: user[:email]
    find('input[alt="edit ssl certificate order"]').click
    click_on 'send activation link to'
  end

  def validation_token
    user.ssl_account.certificate_orders.first.certificate_order_tokens.first.token
  end

  def certificate_result
    ["{\"cert_results\":\"-----BEGIN CERTIFICATE-----\\nMIIF+jCCA+KgAwIBAgIQViPlkNmvT0CfOQCiRxzMyjANBgkqhkiG9w0BAQsFADB+\\nMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMxEDAOBgNVBAcMB0hvdXN0b24x\\nETAPBgNVBAoMCFNTTCBDb3JwMTowOAYDVQQDDDFTU0wuY29tIENsaWVudCBDZXJ0\\naWZpY2F0ZSBJbnRlcm1lZGlhdGUgQ0EgUlNBIFIyMB4XDTIwMDQyODE3MTQyNVoX\\nDTIxMDQyNzE3MTQyNVowIzEhMB8GCSqGSIb3DQEJARYSbC5za3l3YWxrZXJAZ2cu\\nY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw3dCI68zJ5GemXND\\nIJcdQG8FZRjC3PuzVzfsyq7luDKV+3zIVst8XrHLQhVRoyTlxsJ/l4hjXYXSSBiW\\nV7gYX4qJJ88r7AeS/0P6WakoJPB6jtIGtJWCPNNqhsw8IGCjfmCpRf9T1wxTmGwf\\nhfmtP/NsRbi1tdA6cp/EFYZ1xL+5ssln9ABZnQ9NalSnVL3dqbk2ROcxPFmB5U5T\\nFqhHE7wkFZAl9IN+pxtiMTmiUBUuEKvdCll1ZJIiQx9XJ+pvWQ3nlU1OwuGlLf1s\\nbOccr4qFI4x5Wr7bkeqLPjRmD3S1vO9Gje+IWBPJzuKH2TbY02mNzHrpVAJdlaxW\\nWUd5hwIDAQABo4IBzTCCAckwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBTjMdjt\\n7m6neBom94ZEZVQqS1M5sTCBgwYIKwYBBQUHAQEEdzB1MFEGCCsGAQUFBzAChkVo\\ndHRwOi8vd3d3LnNzbC5jb20vcmVwb3NpdG9yeS9TU0xjb20tU3ViQ0EtY2xpZW50\\nQ2VydC1SU0EtNDA5Ni1SMi5jcnQwIAYIKwYBBQUHMAGGFGh0dHA6Ly9vY3Nwcy5z\\nc2wuY29tMB0GA1UdEQQWMBSBEmwuc2t5d2Fsa2VyQGdnLmNvbTBXBgNVHSAEUDBO\\nMA4GDCsGAQQBgqkwAQMCATA8BgwrBgEEAYKpMAEDBQcwLDAqBggrBgEFBQcCARYe\\naHR0cHM6Ly93d3cuc3NsLmNvbS9yZXBvc2l0b3J5MB0GA1UdJQQWMBQGCCsGAQUF\\nBwMCBggrBgEFBQcDBDBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3Jscy5zc2wu\\nY29tL1NTTGNvbS1TdWJDQS1jbGllbnRDZXJ0LVJTQS00MDk2LVIyLmNybDAdBgNV\\nHQ4EFgQUdq5nYeqrO3ATwWdGmzoLyJ7uoe8wDgYDVR0PAQH/BAQDAgWgMA0GCSqG\\nSIb3DQEBCwUAA4ICAQB/3OU3xLGzGO3r4QCpfN+nGCkN1gex/W3TFaDY8Ai+VadS\\nwomRvsVi1USBoifwX9uu9W+Yny5hQU48FzK+0k/nBkFu8AU7BgSfm8sk84v1Obt0\\n6kyXrmsdUWqNtY4RqeJZYqWNIfsTZDhZL5r5OhbFT0W6tOoXo6exselkw7aZqNEN\\nBAjg9kjKIblDFhIo85osDPCSbzUmv7JctM6ETVtRBAC9HPp7LShktPyKIQZwYuEn\\n3BboPmhXulyLNgDQDHJAK3fqgrr3Iw2bopRxbsz5AHdqlVA1LEu8zVbZRndgLSMN\\nAzcVJI7z4RLS0uG/bR5AS06Q0YzT4/ESINL1gIRyDDmtOzzNmWPG76xvrt7UdNsR\\nTpzgFUL55bCy941yLDnk+rd9VeSh9QVXddPEmZtaM4MjG4QUM2Wn3ZiFHrmqpvlD\\nD+CyzHDnqAJVCfhFgTcWDHpOnrBbgLySO/S4eZBFHE9UhYHNUMM/SWiLvNuhGOTr\\nLrqpRfOMMnhrvZrXJBT/zg7M2CTWO8HpwCVEwwbf+/xlPPoSBjNUkBVCuRltNdAj\\n2qTxKEz+yoQ4bBkCl6GguzkxkRUklEqKtyI+rQ2qVZzs5BYYTU0tQWc31o9V6jfP\\nyhcZWvpEcnwvJS32powg81jxSabXawoAeCE4a/4k/TqEeUnoOFt8ncwPj4LDZQ==\\n-----END CERTIFICATE-----\\n-----BEGIN CERTIFICATE-----\\nMIIG/jCCBOagAwIBAgIQB3b8mr5tzlg157+gxKZGujANBgkqhkiG9w0BAQsFADCB\\nijELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRAwDgYDVQQHDAdIb3VzdG9u\\nMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24xPzA9BgNVBAMMNlNTTC5jb20gUm9v\\ndCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSBSU0EgLSBEZXZlbG9wbWVudDAeFw0x\\nOTA0MTkxNDU1MzFaFw0zNDA0MTUxNDU1MzFaMH4xCzAJBgNVBAYTAlVTMQ4wDAYD\\nVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjERMA8GA1UECgwIU1NMIENvcnAx\\nOjA4BgNVBAMMMVNTTC5jb20gQ2xpZW50IENlcnRpZmljYXRlIEludGVybWVkaWF0\\nZSBDQSBSU0EgUjIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC3hZVx\\nyVBItFKxlTBSAeI85Nl0fvHApdSQJoBBkQ0OvZpJD0GQJbwoJc51lAunllFCNV9R\\nG9rbRfw6adRIuZwZV0bnLRzSZtb72phQtGj6XkbSRj7YO8X6Rhe5o0+AHE5wxk1S\\nnxh9j7U1zyoekVtwhwzrnoKtKugYgjXM5pzkX0miqYJEGrE+8MUPmipV3/uDh+cl\\n823cRN6jrTtv8GAwoSiFVCGVmJ6rWQw6uUY07rBapEH0klLiQE51kkLQe5AJrPNZ\\njq3PpxeBAymXzOWDb9Y8MinBzVBAINSl3yRf3prcUIJGvqRG6Lcf45akrPlZRz+K\\nlq3i2ndE15nwedOjKk8cSc3d218eBIffsUInEtPuyuAwYXDkGynzm27MRV3WXohc\\n92qbBb6HvFa1HCuGfsMexmwlf766sl7a+wRC/luQKTaMUro25WyiDWCv8kIEPyAQ\\nyFXWoat0xa0/YI60mZd77kzlMh9leQI3s+DpgM6Sdzij9Dc+tx5jfcq1MDNQxxH0\\nI0thxqSxcsSBw9B2mFM8/FDSSF90vkCKmU0LBIv7vwYMBAnh8NDTTlsNbGnJPB5Q\\nmwvOiJAOHVG7ZgR/BkH53BzenTaKpDgSu8T9RBptKmDOlZ6om8aBoO3LkM/0LbAu\\nFb3Fidwo/NCL/jZWndGA/Yr/nahUzGZbgRGFNQIDAQABo4IBaTCCAWUwEgYDVR0T\\nAQH/BAgwBgEB/wIBADAfBgNVHSMEGDAWgBRPL0w6rsZx6v3y1pM8ld5Ud/EuETCB\\ngwYIKwYBBQUHAQEEdzB1MFEGCCsGAQUFBzAChkVodHRwOi8vd3d3LnNzbC5jb20v\\ncmVwb3NpdG9yeS9TU0xjb21Sb290Q2VydGlmaWNhdGlvbkF1dGhvcml0eVJTQS5j\\ncnQwIAYIKwYBBQUHMAGGFGh0dHA6Ly9vY3Nwcy5zc2wuY29tMBEGA1UdIAQKMAgw\\nBgYEVR0gADApBgNVHSUEIjAgBggrBgEFBQcDAgYIKwYBBQUHAwQGCisGAQQBgjcK\\nAwwwOwYDVR0fBDQwMjAwoC6gLIYqaHR0cDovL2NybHMuc3NsLmNvbS9zc2wuY29t\\nLXJzYS1Sb290Q0EuY3JsMB0GA1UdDgQWBBTjMdjt7m6neBom94ZEZVQqS1M5sTAO\\nBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQELBQADggIBAMlRfmG3eTWq1I1mEwS6\\nVdYrepKwnXdbuCuJsgQ6MzYOxAAnGJ3S3GdelWuFvR+eS1YT9NbsxVMmmEM2dxkj\\nm0Md5YnTEs3FqWjmVJNrg6On1EQNGBtO2w39c6+JBfYRc2lNQkHJnGMvdlK9C+DF\\nwdZKagDsFaGu45Ldavtt8MfAW4h08JAkFqVa0mXedZ183KS9erAfh/RdCXXojvcs\\nQQbHUdKBQCHoTHly65mkge70LBxgFHgIv+mIxdSFWWpuub3qa1y+u9oIw5ldVsuV\\nLaJ4pxV+mCtcEmF867I8mtHA/7tnWWY84/puzQ4FPt4xEEJg2o8gWIpj8cfgBTIJ\\nJH6PMTtixrDdpPW25AgEIc7Tjtky9P/Rjdr4zOUZzAr3uFkbVNGmGaz/sbXooBiD\\nXFHrNkNGSL3fZrmD4o3yPeuQZlhHw18qGwpSW42k94hWmGCA8bH0oHM3D/uNSmyf\\nzzorPUPtThD7P8ckhDjEKukp+IEbsS9kDicdYe9N1EC88mLc3cvj8tVDcdoaCLqM\\nu+OfcTYqfvoyEY5BQl0jqcsceSfv5g9XGCf8LJfzf8cEGewywFuBA6NDCFW1kT4V\\nMw5IRJqT+iuVYbnMbrwH82Ioppl+jpGK7ENpa0SWY2Omss/KRabUtfC0TRO034KQ\\n9Qpm9XBYiWPYZ6FlHUo0X4Jb\\n-----END CERTIFICATE-----\\n-----BEGIN CERTIFICATE-----\\nMIIF+zCCA+OgAwIBAgIIIzObig1n8BQwDQYJKoZIhvcNAQELBQAwgYoxCzAJBgNV\\nBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3RvbjEYMBYGA1UE\\nCgwPU1NMIENvcnBvcmF0aW9uMT8wPQYDVQQDDDZTU0wuY29tIFJvb3QgQ2VydGlm\\naWNhdGlvbiBBdXRob3JpdHkgUlNBIC0gRGV2ZWxvcG1lbnQwHhcNMTgwMTE2MTIx\\nNzM0WhcNNDMwMTE3MTIxNzM0WjCBijELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRl\\neGFzMRAwDgYDVQQHDAdIb3VzdG9uMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24x\\nPzA9BgNVBAMMNlNTTC5jb20gUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSBS\\nU0EgLSBEZXZlbG9wbWVudDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB\\nANorZ5Cx/Z2y4v2BRUo2+Pdl9wpa3yZ7ZuszutOaSyA/aI0Lq0cIx2EKszcTfBB2\\nIXC9rEy33X6Em2tHsPwhmhLHX/k+CWHEsm7Sdkm/xOsrq98BmvBGekffii0UMnC6\\nAvjUr9OhovphBDlbotFGcPULxhYtiDggi1iG5/UEOtSgjMgw5cNYQNwmqasMwTs4\\nZvEGzdsZi8EBTRAgopDmYb01XaXYvr5vutYQrtCncnhzoH6giPPa+5GXq+Sl9BsS\\nX1Dwcuk9HaU/BxUrwWyqJkmcSrE0rz5JlD73pD+2SZqPAy+ncCeDTlbWeaS71jTy\\nLjfZD5Z48u/wOqqaliGteWI+EhUklAwV++zfHdP4s0gkyqGfHF5jpud6ffi1+R2S\\nHhX6vrbU3IAaYr256URFss3rmUcKdpzi5dzW24IupIGxq6G13e6DrLDuSY+HzPOt\\nQqdHdPLLFYRWeYtCzdLPOHFWmBPc8NcwAVzJMmSqWiE38P5MrO0FrGzy5MKjkN9r\\nz97q9nqS1iQNr9du7jj7QKzSywEh7+8jQ9WWGPSPLPbjdCojBTKscL/IhNtwg3vs\\npOmcdtcOydgNsxX6pAaT+mFcrBTIWJzKNzAW2jlSNVR3W9SH5lFjl8D55byfpJ/n\\n72i89/6c1mgKWofwAWl5EP90YN6p2K5NZR8X+zS1en1JAgMBAAGjYzBhMA8GA1Ud\\nEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUTy9MOq7Gcer98taTPJXeVHfxLhEwHQYD\\nVR0OBBYEFE8vTDquxnHq/fLWkzyV3lR38S4RMA4GA1UdDwEB/wQEAwIBhjANBgkq\\nhkiG9w0BAQsFAAOCAgEAu7HyfSmnH/7EA2VwLPPcSjXFs1Hoppb0bkdXGQQzIbuj\\nCc8Fl8vt0CMAhKddnU6BFFjYypSp5baTFqj/HQoB8IIJdc58QDlK6N6ArEa+j6k2\\n3u64ZkwfM9Ff5cxOpGLCzCxyxtMPyWNegq+vIWvVMrUSGEalRxfKgI0R4OJlJunr\\n2hr1TYr4dU5YG/RWwiCe7qllo/6NvlfBL1lQX6wp8SbbvaRyHr/j1AGX7ZGaWy1m\\n2Jl178XOxFNaPIaV0adE0lLRyFLGeQrzRLoC+9JbGDQJMxJUhQ8zzH6cJVrkQ6WR\\nNLhJMhLxpkiiGU8BOAG7FNfuN/L9MLdD/OSJdCuunhUuUrnKSVt0LnC5Cy2WCfRC\\ngpGuYBgqN8AnuvyduZ+DfSP4NVkWRaInVc0FfTclGWO4SgNeUIhoD9uIKquQnOcb\\nAd9z3moUorwBl1VZgpiZWmJ3Oc1SpmIHhNL0adXGpPuo09Gag/uPwN4ZuuciHDv1\\nbPAhQdKesjGroA7EiU1eiKkNs1Uli+jAX5Rk2BogdF+IUnJz4mSnT6pYmCL+Q7yJ\\nqZ0zJ/Q1Ymx3sPZCdorSbtCcsikEDuWmr3uDetfp63uCYmCCEOog2PXNU+8JSl5C\\nLg3bbsJapACm6UQ/MdieCaZXssyO7wQi/eA1fHCvds5HuWSCn5eRB0vnZHiuS4g=\\n-----END CERTIFICATE-----\\n\",\"cert_common_name\":\"114499994175576305731999081607420759242.crt\"}"]
  end
end
