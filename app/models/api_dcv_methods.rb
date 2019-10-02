class ApiDcvMethods < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :csr, presence: true, if: lambda{|c|c.ref.blank?}

  attr_accessor :dcv_methods, :instructions, :md5_hash, :sha1_hash, :sha2_hash, :dns_sha2_hash, :dns_md5_hash, :ca_tag

  INSTRUCTIONS="https://#{Settings.portal_domain}/faqs/ssl-dv-validation-requirements/"
end
