# == Schema Information
#
# Table name: validation_rules
#
#  id                                   :integer          not null, primary key
#  applicable_validation_methods        :text(65535)
#  description                          :string(255)
#  notes                                :text(65535)
#  operator                             :string(255)
#  required_validation_methods          :text(65535)
#  required_validation_methods_operator :string(255)      default("AND")
#  created_at                           :datetime
#  updated_at                           :datetime
#  parent_id                            :integer
#
# Indexes
#
#  index_validation_rules_on_parent_id  (parent_id)
#

# The actual validation rule or requirement

class ValidationRule < ApplicationRecord
  belongs_to  :parent, :foreign_key => :parent_id
  serialize   :applicable_validation_methods
  serialize   :required_validation_methods
  has_many    :validation_rulings
  has_many    :certificates, :through=>:validation_rulings,
    :source=>:validation_rulable, :source_type=>"Certificate"
  has_many    :validations, :through=>:validation_rulings,
    :source=>:validation_rulable, :source_type=>"Validation"

  #validation types
  EV = %w(ev validation)
  ORGANIZATION = %w(organization validation)
  DOMAIN = %w(domain validation)

  # description
  LEGAL_EXISTENCE="verify legal existence"
  PHYSICAL_EXISTENCE="verify physical/operational existence"

  #methods
  DUNS = %w(duns\ and\ bradstreet\ (hoovers))
  EV_AUTHORIZATION_FORM = %w(ev\ authorization\ form)
  EV_SUBSCRIBER_AGREEMENT = %w(ev\ subscriber\ agreement)
  SUBSCRIBER_AGREEMENT = %w(subscriber\ agreement)
  CERTIFICATE_REQUEST_FORM = %w(certificate\ request\ form)
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
    MERCHANT_CERTIFICATE + DUNS

  default_scope{ order("description asc")}

  def self.add_ev_rules
    ValidationRule.create description: "ev agreement and request form",
                          applicable_validation_methods: EV_SUBSCRIBER_AGREEMENT+EV_AUTHORIZATION_FORM,
                          required_validation_methods: EV_SUBSCRIBER_AGREEMENT+EV_AUTHORIZATION_FORM,
                          required_validation_methods_operator: "AND"
    ValidationRule.create description: LEGAL_EXISTENCE,
                          applicable_validation_methods: ORG_VALIDATION_METHODS
    ValidationRule.create description: PHYSICAL_EXISTENCE,
                          applicable_validation_methods: ORG_VALIDATION_METHODS
  end

end
