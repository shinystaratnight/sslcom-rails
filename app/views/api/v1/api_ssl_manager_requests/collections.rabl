object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  collection @results, :object_root => false
  attributes :common_name, :subject_alternative_names, :effective_date, :expiration_date, :serial, :issuer, :status, :created_at, :updated_at
end
