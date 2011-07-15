class EmailValidator < ActiveModel::EachValidator
  EMAIL_FORMAT = '/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i'
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || "is not an email") unless
      value =~ Regexp.new(EMAIL_FORMAT)
  end
end