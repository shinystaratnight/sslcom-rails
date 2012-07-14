class ApiCertificateRetrieve < ApiCertificateRequest
  QUERY_TYPE = %w(status end_certificate all_certificates ca_bundle)
  RESPONSE_TYPE = [*(0..3)]


  validates :account_key, :secret_key, :ref, presence: true
  validates :query_type, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateRetrieve::QUERY_TYPE,
    message: "needs to be one of the following: #{QUERY_TYPE.join(', ')}"}
  validates :response_type, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateRetrieve::RESPONSE_TYPE,
    message: "needs to be one of the following: #{RESPONSE_TYPE.join(', ')}"}, if: lambda{|c|c.response_type}
  validates :show_validity_period, format: /[YNyn]/, if: lambda{|c|c.show_validity_period}
  validates :show_domains, format: /[YNyn]/, if: lambda{|c|c.show_domains}
  validates :show_ext_status, format: /[YNyn]/, if: lambda{|c|c.show_ext_status}

  attr_accessor :validity_period, :domains, :ext_status, :certificates

end
