class ApiCertificateQuote < ApiCertificateRequest
  QUERY_TYPE = %w(order_status_only end_certificate all_certificates ca_bundle)
  RESPONSE_TYPE = %w(zip netscape pkcs7 individually)
  RESPONSE_ENCODING = %w(base64 binary)

  validates :account_key, :secret_key, :ref, presence: true
  validates :query_type, presence: true,
    inclusion: {in: ApiCertificateRetrieve::QUERY_TYPE,
    message: "needs to be one of the following: #{QUERY_TYPE.join(', ')}"}
  validates :response_type, presence: true,
    inclusion: {in: ApiCertificateRetrieve::RESPONSE_TYPE,
    message: "needs to be one of the following: #{RESPONSE_TYPE.join(', ')}"}, if: lambda{|c|c.response_type}
  validates :response_encoding, presence: true,
    inclusion: {in: ApiCertificateRetrieve::RESPONSE_ENCODING,
    message: "needs to be one of the following: #{RESPONSE_ENCODING.join(', ')}"}, if: lambda{|c|c.response_encoding}
  validates :show_validity_period, format: /[YNyn]/, if: lambda{|c|c.show_validity_period}
  validates :show_domains, format: /[YNyn]/, if: lambda{|c|c.show_domains}
  validates :show_ext_status, format: /[YNyn]/, if: lambda{|c|c.show_ext_status}
  validates_presence_of :order_exists, if: lambda{|c|c.ref}

  attr_accessor :validity_period, :domains, :ext_status, :certificates, :order_status, :certificate_order,
                :common_name, :subject_alternative_names, :effective_date, :expiration_date, :algorithm

  def initialize(attributes = {})
    super
    self.query_type ||= "all_certificates"
    self.response_type ||= "individually"
    self.response_encoding ||= "base64"
  end

  def order_exists
    self.certificate_order=CertificateOrder.find_by_ref(self.ref)
    errors[:ref] << "doesn't exist'" unless self.certificate_order
  end

end
