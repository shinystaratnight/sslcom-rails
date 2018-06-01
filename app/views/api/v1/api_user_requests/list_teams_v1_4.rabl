object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  collection @results, :object_root => false
  attributes :acct_number, :roles, :created_at, :updated_at, :status, :ssl_slug, :company_name, :issue_dv_no_validation, :billing_method
end
