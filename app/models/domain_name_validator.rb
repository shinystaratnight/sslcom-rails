class DomainNameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if value.is_a? Array
      value.each do |val|
        record.errors[attribute] << (options[:message] || "#{val} is not a valid domain name") unless
            DomainNameValidator.valid?(val)
      end
    else
      record.errors[attribute] << (options[:message] || "#{value} is not a valid domain name") unless
          DomainNameValidator.valid?(value)
    end
  end

  def self.valid?(domain,wildcard=true)
    regex = wildcard ? /[^a-zA-Z0-9\.\*-]+/ : /[^a-zA-Z0-9\.-]+/
    PublicSuffix.valid?(domain, default_rule: nil, ignore_private: true) and !(domain =~ regex)
  end
end