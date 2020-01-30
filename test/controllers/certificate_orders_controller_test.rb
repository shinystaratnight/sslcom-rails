require 'test_helper'

describe CertificateOrdersController do
  # Note to developers: Extract this logic into cleaner FactoryBot setup
  before do
    initialize_roles
    initialize_triggers
    login(role: owner)
  end

  describe 'update_csr' do
    describe 'domain names' do
      let(:fqdn) {
        "-----BEGIN CERTIFICATE REQUEST-----
        MIICrjCCAZYCAQAwaTELMAkGA1UEBhMCVVMxFDASBgNVBAMMC2V4YW1wbGUuY29t
        MRAwDgYDVQQHDAdIb3VzdG9uMRAwDgYDVQQKDAdTU0wuY29tMQ4wDAYDVQQIDAVU
        ZXhhczEQMA4GA1UECwwHU1NMLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
        AQoCggEBAMMexVw+K8qzoqK+YRhyEYdxksx79m0KPLo4RHGcDq6pV637ykbT6lTj
        LSymfOH+E/7cnbnO0sQEokvpsYiVLcJGIKNzGJKxWtJpypmEz0nvfN9gZSU4RAh1
        U4MyO3X1TdaCw+K1FvD56V3//rrapHrVg7OprpHZrPoE0cpeh1Jwwqzp+4qqLTnp
        x4+Av/qOMB4hxUgJw9s01keJguEQHzdhE7H6JF8FJTtaf9k0Ze+6I756HA7b/Jx7
        HzvM7vdv8LrRB1qYmTKe3bS3WlXgmWYVZOYb/xG5uGug8ghz/4A4JXTDx/KEb3os
        4nEuwSXB6IzVP1MUj+ZXfitLxqj1KwECAwEAAaAAMA0GCSqGSIb3DQEBCwUAA4IB
        AQBtbUtv6gxSv6v+i+9aIReHsYGjIDM6XgIOrfygcHrMyGBJJQQgirQ90TVolu+C
        kRujfjo01YK/EgSqM0Z+S+lIRjG7OGiQ86pJSdI7ZIy/sD7aOLLw7csA0e/aAJEL
        YkMYAxUPpbRhhRo43WTiR1dN9lhXDQA3zDRsYMFsBqQksM4iR7EP356NSNVvRo/P
        i8uQ1SsfyrOwoCUCopOLdhQq4bzIwuR6mZ2z2ksu9pUZolfArfFq1ByYIDDGXv55
        yKDkQBcnU/oMONsuIsUyr5SKPbLVwSp8k9k61unEt30kYhiUgggbHILusT9hCfBv
        cpJ6EXAChQ0+6c8ND/mik0SG
        -----END CERTIFICATE REQUEST-----"
      }

      let(:numerical_domain_name) {
        "-----BEGIN CERTIFICATE REQUEST-----
        MIICsjCCAZoCAQAwbTELMAkGA1UEBhMCVVMxGDAWBgNVBAMMDzEwNi4yNTUuMjEy
        LjEyMzEQMA4GA1UEBwwHSG91c3RvbjEQMA4GA1UECgwHU1NMLmNvbTEOMAwGA1UE
        CAwFVGV4YXMxEDAOBgNVBAsMB1NTTC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB
        DwAwggEKAoIBAQDCIs3VdUK9hAWxTn1q+eMx/epllcXe67ub1JtwaKwCoZds4+Mu
        09kHUeUX8tMhQJeZJWe6fMov6GALCem/hUNAt98Oo7txcwsCdYhl2K49ULmt90w0
        NTk+ybYZqYXVhmZKuPrHuKleXa1leLcFmSRzLHciOjU7cIfS7ZvrVJ/DI2pnCfel
        0OzHvq1azpcrxRWr8lmiBVWl2Tgtd+aINGoHVzpkVEBZ7Jn5CCIoDZHU8tTuPx+G
        8+uBHSFHKcfS8Z2cuV9cI8orIACuYMWuq05a+IVkSjpEw1W3+F/rUZfSUD+TNcPw
        3PgQWjWu3oCz67b44YbncBIQzZNPmQIG6QnxAgMBAAGgADANBgkqhkiG9w0BAQsF
        AAOCAQEAItFaVxN/VgQW4KdS+nIincWN6hcKAMaUTYCrMWNNH5rymsbrikpXXrtr
        ZWheglPQKEq+ymBGdr8K8WZQDcyGxedPuFz8pNUDdI2YIHIU499NlT4b7EQWYVNK
        GebTelUhMW39xjUyCdNgVkXA2cuD2vV/X/CUZrBaNWo2XXgDjh9SORwnB6/I0h1O
        YFzY6yRXL4Cyy8Ib3B5j/PFPVh6CgspFqGkpcZwbk2iumlAQNBp1xG9WB7aL9rYH
        l+9eeLRNmZj0soZDK8/aUVwiCNLZDpXRCOS35rO9+J7wObaTTfRmWDEriOSvKgXn
        5rg1kSFcn61bIYdGDLVTMlrHTN9tBw==
        -----END CERTIFICATE REQUEST-----"
      }

      def create_certificate(type)
        cert = create(:certificate_with_certificate_order, type)
        co = build(:certificate_order)
        co.sub_order_items << cert.product_variant_items.first.sub_order_item
        co.ssl_account.users << @user
        co.certificate_contents << build(:certificate_content)
        order = build(:order)
        co.orders << order
        co.save
        co
      end

      it 'rejects numerical ip addresses for free certificates' do
        free_cert = create_certificate(:freessl)

        params = {
          "certificate_order": {
            "certificate_contents_attributes": {
              "0": {
                "signing_request": numerical_domain_name,
                "server_software_id": "1",
              }
            }
          },
          "common_name": "106.255.212.123",
          "id": "#{free_cert.ref}"
        }

        put :update_csr, params
        assert_template :submit_csr
        assert_select 'div.errorExplanation', flash[:error]
      end

      it 'rejects numerical ip addresses for basic ssl certificates' do
        basicssl_cert = create_certificate(:basicssl)

        params = {
          "certificate_order": {
            "certificate_contents_attributes": {
              "0": {
                "signing_request": numerical_domain_name,
                "server_software_id": "1",
              }
            }
          },
          "common_name": "106.255.212.123",
          "id": "#{basicssl_cert.ref}"
        }

        put :update_csr, params
        assert_template :submit_csr
        assert_select 'div.errorExplanation', flash[:error]
      end

      it 'rejects numerical ip addresses for ev certificates' do
        ev_cert = create_certificate(:evssl)

        params = {
          "certificate_order": {
            "certificate_contents_attributes": {
              "0": {
                "signing_request": numerical_domain_name,
                "server_software_id": "1",
              }
            }
          },
          "common_name": "106.255.212.123",
          "id": "#{ev_cert.ref}"
        }

        put :update_csr, params
        assert_template :submit_csr
        assert_select 'div.errorExplanation', flash[:error]
      end

      describe 'ucc certs' do
        it 'rejects numerical ip addresses for ev ucc certificates' do
          evucc_cert = create_certificate(:evuccssl)


          params = {
            "certificate_order": {
              "certificate_contents_attributes": {
                "0": {
                  "signing_request": numerical_domain_name,
                  "server_software_id": "1",
                  "additional_domains": "106.255.212.123"
                }
              }
            },
            "common_name": "",
            "id": "#{evucc_cert.ref}"
          }

          put :update_csr, params
          assert flash[:error]
        end

        it 'rejects numerical ip addresses for ev ucc certificates in the additional_domains parameter' do
          evucc_cert = create_certificate(:evuccssl)

          params = {
            "certificate_order": {
              "certificate_contents_attributes": {
                "0": {
                  "signing_request": fqdn,
                  "server_software_id": "1",
                  "additional_domains": "example.com 106.255.212.123"
                }
              }
            },
            "common_name": "",
            "id": "#{evucc_cert.ref}"
          }

          put :update_csr, params
          assert flash[:error]
        end
      end
    end
  end

  it 'allows a user to download certificate orders in csv format' do
    certificate = create(:certificate_with_certificate_order)
    co = build(:certificate_order)
    co.sub_order_items << certificate.product_variant_items.first.sub_order_item
    co.ssl_account.users << @user
    co.certificate_contents << build(:certificate_content)
    co.save

    post :download_certificates, co_ids: co.id, format: :csv
    response.code.must_equal "200"
    response.body.must_match "Order Ref,Order Label,Duration,Signed Certificate,Status,Effective Date,Expiration Date"
  end
end
