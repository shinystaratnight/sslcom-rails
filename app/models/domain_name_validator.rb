class DomainNameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if value.is_a? Array
      value.each do |val|
        record.errors[attribute] << (options[:message] || "#{val} is not a valid domain name") unless
            PublicSuffix.valid?(val, default_rule: nil, ignore_private: true) or
                val =~ /[^a-zA-Z0-9\.-]/
      end
    else
      record.errors[attribute] << (options[:message] || "#{value} is not a valid domain name") unless
          PublicSuffix.valid?(value, default_rule: nil, ignore_private: true) or
              value =~ /[^a-zA-Z0-9\.-]/
    end
  end
end