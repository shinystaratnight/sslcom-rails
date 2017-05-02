# This class represent requests sent to the CA (ie Comodo or the SSL.com Root CA)

class CaCertificateRequest < CaApiRequest

  def order_number
    m=response.match(/(?<=orderNumber=)(.+?)&/)
    m[1] unless m.blank?
  end

  def certificate_id
    m=response.match(/(?<=certificateID=)(.+?)&/)
    m[1] unless m.blank?
  end

  def total_cost
    m=response.match(/(?<=totalCost=)(.+?)&/)
    m[1].to_f unless m.blank?
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