object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  if @result.debug
    glue @result do
      attributes :ref, :api_request, :api_response
    end
  else
    glue @result do
      attributes :ref
    end
  end
end
