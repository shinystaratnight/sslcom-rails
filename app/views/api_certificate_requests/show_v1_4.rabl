object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :order_status, :registrant, :certificates, :common_name, :subject_alternative_names, :validations, :effective_date, :expiration_date, :algorithm, :domains, :site_seal_code
  end
end
