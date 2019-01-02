class Registrant < Contact
  
  enum registrant_type: { individual: 0, organization: 1 }
  
  after_save :set_default_status
  after_destroy :release_dependant_contacts

  validates_presence_of :contactable
  # validates_acceptance_of :validation,
  #   if: Proc.new {|r|
  #     !r.reusable? && (
  #       r.contactable &&
  #       r.contactable.certificate_order &&
  #       r.contactable.certificate_order.ssl_account.has_role?("reseller")
  #     )
  #   }
  validates_presence_of :company_name, :address1, :city, :state, :postal_code, :country,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && 
        r.contactable.certificate_order.certificate.requires_company_info?
    }
  validates_presence_of :phone,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }
  validates_presence_of :title,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }
  validates_presence_of :email,
    if: Proc.new{|r|
      !r.reusable? && r.contactable &&
      r.contactable.certificate_order.certificate.is_code_signing?
    }
  validates_presence_of :first_name, :last_name,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_client_pro? ||
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }

  validates_presence_of :business_category, :incorporation_city, :incorporation_state,
                        :company_number, :incorporation_country,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && r.contactable.certificate_order.certificate.is_ev?
    }

  validates :city, :state, :country, :email, presence: true,
    if: proc { |r| r.reusable? && (r.organization? || r.individual?) }
  validates :company_name, :phone, presence: true, if: proc { |r| r.reusable? && r.organization? }
  validates :first_name, :last_name, presence: true, if: proc { |r| r.reusable? && r.individual? }

  protected
  
  def set_default_status
    if reusable? && status.nil?
      self.in_progress!
    end
  end

  def reusable?
    contactable.is_a?(SslAccount)
  end

  def self.get_validated_registrants(team)
    Registrant.where(
      contactable_type: team.class,
      contactable_id: team.id,
      status: statuses[:validated]
    )
  end

  private

  def release_dependant_contacts
    Contact.where(parent_id: id).update_all(parent_id: nil)
  end
end
