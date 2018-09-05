object false
if !@result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  glue @result do
    attributes :ref
  end
end
