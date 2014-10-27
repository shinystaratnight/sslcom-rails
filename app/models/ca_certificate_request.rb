class CaCertificateRequest < CaApiRequest

  def order_number
    response =~ /(?<=orderNumber=)(.+?)&/
    $1
  end

  def certificate_id
    response =~ /(?<=certificateID=)(.+?)&/
    $1
  end

  def total_cost
    response =~ /(?<=totalCost=)(.+?)&/
    $1.to_f
  end

  def response_to_hash
    CGI::parse(response)
  end

  def response_error_code
    codes = response_to_hash
    codes['errorCode'].blank? ? "" : codes['errorCode'][0]
  end

  def response_error_message
    codes = response_to_hash
    codes['errorMessage'].blank? ? "" : codes['errorMessage'][0].gsub(/comodo/i,'SSL.com').gsub(/\!AutoApplySSL/,'api access')
  end

  def response_certificate_eta
    codes = response_to_hash
    codes['expectedDeliveryTime'] ? codes['expectedDeliveryTime'][0] : ""
  end

  def response_certificate_status
    codes = response_to_hash
    codes['certificateStatus'] ? codes['certificateStatus'][0] : ""
  end


end