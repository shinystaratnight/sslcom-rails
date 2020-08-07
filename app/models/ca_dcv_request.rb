class CaDcvRequest < CaApiRequest

  def success?
    !!(response=~/^0\n/)
  end

  ["domain_name", "whois_email", "level2_email", "level3_email", "level4_email", "level5_email"].each do |i|
    define_method "#{i}" do
      choices = parse_email_choices
      choices.shift #remove status
      choices = Hash[*choices.reverse]
      choices.select{|k,v|v=="#{i}"}.map{|k,v|k}
    end
  end

  def email_address_choices
    success? ? whois_email+level2_email+level3_email+level4_email+level5_email : []
  end

  private

  def parse_email_choices
    response.split(/[\n|\t]/)
  end
end
