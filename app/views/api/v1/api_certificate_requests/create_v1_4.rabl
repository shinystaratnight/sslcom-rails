object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  if @result.debug
    glue @result do
      attributes :ref, :registrant, :order_status, :validations, :order_amount, :external_order_number, :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :certificates, :api_request, :api_response
    end
  else
    glue @result do
      attributes :ref, :registrant, :order_status, :validations, :order_amount, :external_order_number, :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :certificates
    end
  end
end
