object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :id, :artifacts_status, :publish_to_site_seal, :viewing_method, :publish_to_site_seal_approval
  end
end
