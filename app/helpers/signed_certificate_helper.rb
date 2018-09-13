module SignedCertificateHelper
  def issuer_items(issuer)
    results = []
    items = issuer.split(',')

    items.each do |item|
      key = item.split('=')[0]
      value = item.split('=')[1]

      if key == 'CN'
        results << ('Common Name (CN) : ' + value)
      elsif key == 'OU'
        results << ('Organization Unit (OU) : ' + value)
      elsif key == 'O'
        results << ('Organization (O) : ' + value)
      elsif key == 'C'
        results << ('Country (C) : ' + value)
      end
    end

    results
  end
end
