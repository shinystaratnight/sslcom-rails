object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :ref, :menu, :sub_main, :cert_details, :smart_seal, :is_admin
  end
end
