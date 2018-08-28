object false
if !@result.errors.blank?
  glue @result do
    attributes :errors
  end
elsif !@result.message.blank?
  glue @result do
    attributes :message
  end
else
  glue @result do
    attributes :ref, :created_at, :updated_at
  end
end
