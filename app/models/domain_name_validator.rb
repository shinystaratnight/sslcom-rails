class DomainNameValidator < ActiveModel::EachValidator

  DOMAIN_NAME_FORMAT = Regexp.new('[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$', Regexp::IGNORECASE+Regexp::EXTENDED)
  GTLDS = Regexp.new('\.('+CertificateContent::ICANN_TLDS.join("|")+')$', Regexp::IGNORECASE+Regexp::EXTENDED)

  def validate_each(record, attribute, value)
    if value.is_a? Array
      value.each do |val|
        record.errors[attribute] << (options[:message] || "#{val} is not a valid domain name") if
            ((val =~ DOMAIN_NAME_FORMAT) && (val =~ GTLDS)).blank?
      end
    else
      record.errors[attribute] << (options[:message] || "#{value} is not a valid domain name") if
          ((value =~ DOMAIN_NAME_FORMAT) && (value =~ GTLDS)).blank?
    end
  end
end