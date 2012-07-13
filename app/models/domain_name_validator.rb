class DomainNameValidator < ActiveModel::EachValidator

  DOMAIN_NAME_FORMAT = Regexp.new('[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
                          Regexp::IGNORECASE+Regexp::EXTENDED)

  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || "#{value} is not a valid domain name") unless
      value =~ DOMAIN_NAME_FORMAT
  end
end