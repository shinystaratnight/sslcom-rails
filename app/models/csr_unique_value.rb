
class CsrUniqueValue < ActiveRecord::Base
  belongs_to  :csr
  has_many    :domain_control_validations
end