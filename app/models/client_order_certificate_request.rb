class ClientOrderCertificateRequest < CaApiRequest
  validate :access_key, presence: true
  validate :string_key, presence: true
  validate :csr, presence: true
  validate :product, presence: true
  validate :period, presence: true, format: /\d/, in: NON_EV_PERIODS, if: lambda{|c|c.product=~ /^ev/}
  validate :period, presence: true, format: /\d/, in: EV_PERIODS,
           if: lambda{|c|c.product=~ /^(?!ev)/ && c.product=~ /^(?!dv)/}
  validate :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validate :server_software, presence: true, format: /\d/, in: ServerSoftware.listing.map(&:id)
  validate :other_domains, presence: false, if: lambda{|c|!c.is_ucc?}
  validate :domain, presence: false, if: lambda{|c|!c.is_ucc?}
  validate :organization_name, presence: true
  validate :street_address_1, presence: true

  before_create :parse_request

  NON_EV_PERIODS = [365, 730, 1095, 1461, 1826]
  EV_PERIODS = [365, 730]

  PRODUCTS = %w(evssl evmdssl ovssl wcssl mdssl dvssl uccssl)

  def parse_request
    co = CertificateOrder.new
  end


end
