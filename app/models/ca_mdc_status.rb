class CaMdcStatus < CaApiRequest

  def response_code
    response =~ /\A(\d)\n/
    $1.to_i
  end

  def domain_status
    vals=response.split("&").select{|v|v=~/\d+_/}.map{|s|s.split("=")}.transpose
    unless vals.blank?
      ki, vi, status=1, 0, {}
      (vals[0].count/3).times do |v|
        status.merge!({vals[1][vi]=>{"method"=>vals[1][vi+1].gsub("+"," "),"status"=>vals[1][vi+2].gsub("+"," ")}})
        vi+=3
      end
      status
    end
  end

  def status
    response =~ /.+\n(.+?)\Z/m
    $1
  end

end
