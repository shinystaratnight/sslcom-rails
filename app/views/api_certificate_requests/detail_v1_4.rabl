object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :ref, :menu, :main, :sub_main, :certificate_content, :in_limit, :registrant, :download, :domain_validation, :validation_document, :visit, :contacts, :certificate_contents, :api_commands
  end
end
