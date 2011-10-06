class CaCertificateRequest < CaApiRequest

  def order_number
    response =~ /(?<=orderNumber=)(.+?)&/
    $1
  end

end