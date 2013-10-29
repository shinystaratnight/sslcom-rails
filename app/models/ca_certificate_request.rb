class CaCertificateRequest < CaApiRequest

  def order_number
    response =~ /(?<=orderNumber=)(.+?)&/
    $1
  end

  def total_cost
    response =~ /(?<=totalCost=)(.+?)&/
    $1.to_f
  end
end