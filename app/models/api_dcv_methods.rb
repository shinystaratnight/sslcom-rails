class ApiDcvMethods < ApiCertificateRequest
  validates :account_key, :secret_key, :ref, presence: true

  attr_accessor :dcv_methods, :instructions, :md5_hash, :sha1_hash

  INSTRUCTIONS="https://support.ssl.com/Knowledgebase/Article/View/29/0/alternative-methods-of-domain-control-validation-dcv"
end