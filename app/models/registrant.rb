class Registrant < Contact
  #recomment after migration from V2
#  validates_acceptance_of :validation,
#    :if=>Proc.new { |r|
#    r.contactable.certificate_order &&
#      r.contactable.certificate_order.ssl_account.has_role?("reseller") }
#  validates_presence_of  :company_name, :address1, :city, :state, :postal_code,
#    :country, :contactable
end
