class CaRetrieveCertificate < CaApiRequest

  def response_code
    response =~ /\A(\-?\d+)/
    $1.to_i
  end

  #format is as follows - response_code, cert, status
  def certificate
    response =~ /\A\d\n(.+)\n\n.+?/m if response_code==2
    $1
  end

  def status
    response =~ /.+\n(.+?)\Z/m
    $1
  end

end
