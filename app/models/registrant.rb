class Registrant < Contact
  
  enum registrant_type: { individual: 0, organization: 1 }

  unless MIGRATING_FROM_LEGACY
    validates_acceptance_of :validation,
      if: Proc.new {|r| 
        !r.reusable? && (
          r.contactable.certificate_order &&
          r.contactable.certificate_order.ssl_account.has_role?("reseller")
        )
      }
    validates_presence_of :contactable
    validates_presence_of :company_name, :address1, :city, :state, :postal_code, :country,
      if: Proc.new{|r| !r.reusable? && r.contactable.certificate_order.certificate.requires_company_info?}
    validates_presence_of :phone,
      if: Proc.new{|r|
        !r.reusable? && (
          r.contactable.certificate_order.certificate.is_code_signing? ||
          r.contactable.certificate_order.certificate.is_client_enterprise? ||
          r.contactable.certificate_order.certificate.is_client_business?
        )
      }
    validates_presence_of :title,
      if: Proc.new{|r|
        !r.reusable? && (
          r.contactable.certificate_order.certificate.is_client_enterprise? ||
          r.contactable.certificate_order.certificate.is_client_business?
        )
      }
    validates_presence_of :email,
      if: Proc.new{|r|
        !r.reusable? &&
        r.contactable.certificate_order.certificate.is_code_signing?
      }
    validates_presence_of :first_name, :last_name,
      if: Proc.new{|r|
        !r.reusable? && (
          r.contactable.certificate_order.certificate.is_client_pro? ||
          r.contactable.certificate_order.certificate.is_code_signing? ||
          r.contactable.certificate_order.certificate.is_client_enterprise? ||
          r.contactable.certificate_order.certificate.is_client_business?
        )
      }
  end
  
  validates :address1, :city, :state, :country, :postal_code, :email, presence: true,
    if: proc { |r| r.reusable? && (r.organization? || r.individual?) }
  validates :company_name, presence: true, if: proc { |r| r.reusable? && r.organization? }
  validates :first_name, :last_name, presence: true, if: proc { |r| r.reusable? && r.individual? }
  
  protected
  
  def reusable?
    contactable.is_a?(SslAccount) && !registrant_type.nil?
  end
end
