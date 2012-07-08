object false
glue @acr do
  attributes :errors
  glue :csr_obj do
    attributes errors: :csr_errors
  end
end
