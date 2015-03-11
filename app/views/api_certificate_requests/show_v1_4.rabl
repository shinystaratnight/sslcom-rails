object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :description, :order_status, :registrant, :certificates, :common_name, :domains_qty_purchased, :wildcard_qty_purchased, :subject_alternative_names, :validations, :effective_date, :expiration_date, :algorithm, :domains, :site_seal_code
  end
end
