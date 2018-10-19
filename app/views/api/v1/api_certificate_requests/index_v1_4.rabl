object false
unless @result.errors.blank?
  glue @result do
    attributes :errors
  end
else
  collection @results, :object_root => false
  attributes :ref, :if => lambda { |result| @fields.include?('ref') }
  attributes :description, :if => lambda { |result| @fields.include?('description') }
  attributes :order_status, :if => lambda { |result| @fields.include?('order_status') }
  attributes :order_date, :if => lambda { |result| @fields.include?('order_date') }
  attributes :registrant, :if => lambda { |result| @fields.include?('registrant') }
  attributes :certificates, :if => lambda { |result| @fields.include?('certificates') }
  attributes :common_name, :if => lambda { |result| @fields.include?('common_name') }
  attributes :domains_qty_purchased, :if => lambda { |result| @fields.include?('domains_qty_purchased') }
  attributes :wildcard_qty_purchased, :if => lambda { |result| @fields.include?('wildcard_qty_purchased') }
  attributes :subject_alternative_names, :if => lambda { |result| @fields.include?('subject_alternative_names') }
  attributes :validations, :if => lambda { |result| @fields.include?('validations') }
  attributes :effective_date, :if => lambda { |result| @fields.include?('effective_date') }
  attributes :expiration_date, :if => lambda { |result| @fields.include?('expiration_date') }
  attributes :algorithm, :if => lambda { |result| @fields.include?('algorithm') }
  attributes :domains, :if => lambda { |result| @fields.include?('domains') }
  attributes :site_seal_code, :if => lambda { |result| @fields.include?('site_seal_code') }
  attributes :external_order_number, :if => lambda { |result| @fields.include?('external_order_number') }
end
