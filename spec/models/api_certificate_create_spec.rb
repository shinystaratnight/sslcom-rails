require 'spec_helper'

describe ApiCertificateCreate do
  context 'version 1.3' do
    it "creates a certificate order" do
      post '/certificates/1.3/create' do

      end
    end

    it "saves a certificate order when create_certificate_order is called"

    it "parses the basic ssl csr correctly" do
      create :api_credential
      acc = create :api_certificate_create
      expect(Csr.new(body: acc.csr).common_name).to eq("ssl.danskkabeltv.dk")
    end

    it "parses the wildcard ssl csr correctly" do
      create :api_credential
      acc = create :api_certificate_create_wildcard_5yr
      expect(Csr.new(body: acc.csr).common_name).to eq("*.corp.crowdfactory.com")
    end

    it "has a valid csr object" do
      create :api_credential
      acc = create :api_certificate_create
      expect(acc.csr_obj).to be_an_instance_of(Csr)
    end

    it "has a default dcv method" do
      create :api_credential
      expect(create(:api_certificate_create).dcv_method).to eq("http_csr_hash")
    end

    it "places a valid order" do
      create :api_credential
      create :basic_ssl
      acc = create :api_certificate_create
      expect(acc.create_certificate_order).to be_valid
    end

    it "deducts the proper amount when create_certificate_order is called" do
      cred = create :api_credential
      create :basic_ssl
      acc = create :api_certificate_create
      expect(acc.create_certificate_order).to be_instance_of CertificateOrder
      expect(cred.ssl_account.funded_account(true).cents).to eq(95100)
    end

    it "returns error if not enough funds exists" do
      cred = create :api_credential
      create :wildcard_certificate
      acc = create :api_certificate_create_wildcard_5yr
      expect(acc.create_certificate_order).to be_instance_of CertificateOrder
      expect(cred.ssl_account.funded_account(true).cents).to eq(95100)
    end

    it "requires proper validation" do
      create :api_credential
      expect(create :api_certificate_create).to be_valid
    end

    it "is invalid with invalid account key" do
      create :api_credential
      expect(create :api_certificate_create_invalid_account_key).to be_invalid
    end

    it "is invalid without account_key" do
      acc = ApiCertificateCreate.new(account_key: nil)
      expect(acc).to have(1).errors_on :account_key
    end

    it "is invalid without secret_key" do
      acc = ApiCertificateCreate.new(secret_key: nil)
      expect(acc).to have(1).errors_on :secret_key
    end

    it "is invalid without csr" do
      acc = ApiCertificateCreate.new(csr: nil)
      expect(acc).to have(1).errors_on :csr
    end

    it "is invalid without period" do
      acc = ApiCertificateCreate.new(period: nil)
      expect(acc).to have(3).errors_on :period
    end

    it "is invalid with non digit period" do
      acc = ApiCertificateCreate.new(period: 'a')
      expect(acc).to have(2).errors_on :period
    end

    it "is invalid without product" do
      acc = ApiCertificateCreate.new(product: nil)
      expect(acc).to have(3).errors_on :product
    end

    it "is invalid with non digit product" do
      acc = ApiCertificateCreate.new(product: 'a')
      expect(acc).to have(2).errors_on :product
    end

    it "is invalid with 3 digit product not in range" do
      acc = ApiCertificateCreate.new(product: '999')
      expect(acc).to have(1).errors_on :product
    end

    it "is valid with 3 digit product in range" do
      acc = ApiCertificateCreate.new(product: '204')
      expect(acc).to have(0).errors_on :product
    end

    it "is invalid without server_software" do
      acc = ApiCertificateCreate.new(server_software: nil)
      expect(acc).to have(3).errors_on :server_software
    end

    it "is invalid with non-digit server_software" do
      acc = ApiCertificateCreate.new(server_software: "a")
      expect(acc).to have(2).errors_on :server_software
    end

    it "is invalid if server_software not in range" do
      acc = ApiCertificateCreate.new(server_software: "1000")
      expect(acc).to have(1).errors_on :server_software
    end

    it "is valid if server_software is in range" do
      acc = ApiCertificateCreate.new(server_software: "1")
      expect(acc).to have(0).errors_on :server_software
    end

    context "ev certificate order" do
      it "is invalid without organization name" do
        acc = ApiCertificateCreate.new(product: "204", organization_name: nil)
        expect(acc).to have(1).errors_on :organization_name
      end
    end

  end
end
