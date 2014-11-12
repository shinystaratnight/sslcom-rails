object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :order_status, :certificates, :common_name, :subject_alternative_names, :effective_date, :expiration_date, :algorithm
  end
end
