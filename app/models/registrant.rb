class Registrant < Contact
  unless MIGRATING_FROM_LEGACY
    validates_acceptance_of :validation,
      :if=>Proc.new { |r|
      r.contactable.certificate_order &&
        r.contactable.certificate_order.ssl_account.has_role?("reseller") }
    validates_presence_of  :company_name, :address1, :city, :state, :postal_code,
      :country, :contactable
    validates_presence_of :first_name, :last_name, :email, :phone,
                          if: Proc.new{|r|r.contactable.certificate_order.certificate.is_code_signing?}
  end
end
