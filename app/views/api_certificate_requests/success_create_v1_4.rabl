object false
if @result.debug
  glue @result do
    attributes :ref, :order_status, :order_amount, :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :api_request, :api_response
  end
else
  glue @result do
    attributes :ref, :order_status, :order_amount, :certificate_url, :receipt_url, :smart_seal_url, :validation_url
  end
end
