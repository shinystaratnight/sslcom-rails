class DomainControlValidation < ActiveRecord::Base
  has_many :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to :csr
  serialize :candidate_addresses

  validate :email_address_check, unless: lambda{|r| r.email_address.blank?}

  IS_INVALID = "is an invalid email address choice"

  def email_address_check
    errors.add(:email_address, "'#{email_address}' "+IS_INVALID) unless
        candidate_addresses.include?(email_address)
  end

  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now
  end
end
