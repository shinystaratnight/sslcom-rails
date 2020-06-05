class EmailValidator < ActiveModel::EachValidator
  EMAIL_FORMAT = Regexp.new('\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', Regexp::IGNORECASE)

  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || 'is not an email address') unless EMAIL_FORMAT.match?(value)
  end
end
