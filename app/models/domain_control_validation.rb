class DomainControlValidation < ActiveRecord::Base
  has_many :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to :csr
end