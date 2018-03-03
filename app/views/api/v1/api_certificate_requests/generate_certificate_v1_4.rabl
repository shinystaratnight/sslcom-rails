object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :cert_results
  end
end
