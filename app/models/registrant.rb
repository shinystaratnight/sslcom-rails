class Registrant < Contact
  unless MIGRATING_FROM_LEGACY
    validates_acceptance_of :validation,
      :if=>Proc.new { |r|
      r.contactable.certificate_order &&
        r.contactable.certificate_order.ssl_account.has_role?("reseller") }
    validates_presence_of   :contactable
    validates_presence_of   :company_name, :address1, :city, :state, :postal_code, :country,
      if: Proc.new{|r|r.contactable.certificate_order.certificate.requires_company_info?}
    validates_presence_of   :phone,
      if: Proc.new{|r|
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business? }
    validates_presence_of   :title,
      if: Proc.new{|r|
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business? }
    validates_presence_of   :email,
      if: Proc.new{|r|
         r.contactable.certificate_order.certificate.is_code_signing?}
    validates_presence_of   :first_name, :last_name,
      if: Proc.new{|r|
        r.contactable.certificate_order.certificate.is_client_pro? ||
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business? }
  end
end
