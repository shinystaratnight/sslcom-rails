object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  collection @results
  @results.each do |result|
    node(result.ref.to_sym) {{order_status: result.order_status, registrant: result.registrant, certificates: result.certificates, common_name: result.common_name, subject_alternative_names: result.subject_alternative_names, validations: result.validations, effective_date: result.effective_date, expiration_date: result.expiration_date, algorithm: result.algorithm, domains: result.domains, site_seal_code: result.site_seal_code}}
  end
end
