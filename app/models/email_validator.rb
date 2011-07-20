class EmailValidator < ActiveModel::EachValidator
  EMAIL_FORMAT = Regexp.new('^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$', Regexp::IGNORECASE)
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || "is not an email") unless
      value =~ EMAIL_FORMAT
  end
end