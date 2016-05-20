# The actual validation rule or requirement

class ValidationRule < ActiveRecord::Base
  belongs_to  :parent, :foreign_key => :parent_id
  serialize   :applicable_validation_methods
  serialize   :required_validation_methods
  has_many    :validation_rulings
  has_many    :certificates, :through=>:validation_rulings,
    :source=>:validation_rulable, :source_type=>"Certificate"
  has_many    :validations, :through=>:validation_rulings,
    :source=>:validation_rulable, :source_type=>"Validation"

  #validation types
  ORGANIZATION = %w(organization validation)
  DOMAIN = %w(domain validation)

  #methods
  SUBSCRIBER_AGREEMENT = "subscriber agreement"
  CERTIFICATE_REQUEST_FORM = "certificate request form"
  AUTOMATIC_DOMAIN_LOOKUP = %w(automatic\ domain\ lookup)
  MANUAL_DOMAIN_LOOKUP = %w(manual\ domain\ lookup)
  ARTICLES_OF_INCORPORATION = %w(articles\ of\ incorporation)
  CERTIFICATE_OF_FORMATION = %w(certificate\ of\ formation)
  CHARTER_DOCUMENTS = %w(charter\ documents)
  BUSINESS_LICENSE = %w(business\ license)
  DBA = %w(doing\ business\ as)
  REGISTRATION_OF_TRADE_NAME = %w(registration\ of\ trade\ name)
  PARTNERSHIP_PAPERS = %w(partnership\ papers)
  FICTITIOUS_NAME_STATEMENT = %w(fictitious\ name\ statement)
  LICENSE = %w(vendor/reseller/merchant\ license)
  MERCHANT_CERTIFICATE = %w(merchant\ certificate)
  ORG_VALIDATION_METHODS = ARTICLES_OF_INCORPORATION +
    CERTIFICATE_OF_FORMATION + CHARTER_DOCUMENTS + BUSINESS_LICENSE +
    DBA + REGISTRATION_OF_TRADE_NAME + PARTNERSHIP_PAPERS +
    FICTITIOUS_NAME_STATEMENT + LICENSE +
    MERCHANT_CERTIFICATE

  default_scope{ order("description asc")}

end
