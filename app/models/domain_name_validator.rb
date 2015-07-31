class DomainNameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if value.is_a? Array
      value.each do |val|
        record.errors[attribute] << (options[:message] || "#{val} is not a valid domain name") unless
            PublicSuffix.valid?(val)
      end
    else
      record.errors[attribute] << (options[:message] || "#{value} is not a valid domain name") unless
          PublicSuffix.valid?(value)
    end
  end
end