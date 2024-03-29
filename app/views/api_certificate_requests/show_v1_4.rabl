object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :description, :product, :product_name, :order_status, :order_date, :registrant, :certificates, :common_name, :domains_qty_purchased, :wildcard_qty_purchased, :subject_alternative_names, :validations, :effective_date, :expiration_date, :algorithm, :external_order_number, :domains, :site_seal_code, :subscriber_agreement, :server_software, :contacts
  end
end
