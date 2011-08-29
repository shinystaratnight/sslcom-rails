class DomainControlValidation < ActiveRecord::Base
  has_many :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to :csr
  serialize :candidate_addresses

  validate  :email_address_check, unless: lambda{|r| r.email_address.blank?}

  IS_INVALID  = "is an invalid email address choice"

  include Workflow
  workflow do
    state :new do
      event :send, :transitions_to => :sent
      event :satisfy, :transitions_to => :satisfied
    end

    state :sent do
      event :satisfy, :transitions_to => :satisfied

      on_entry do
        self.update_attribute :sent_at, DateTime.now
      end
    end

    state :satisfied do
    end
  end

  def email_address_check
    errors.add(:email_address, "'#{email_address}' "+IS_INVALID) unless
      candidate_addresses.include?(email_address)
  end

  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now
  end

  def is_eligible_to_send?
    !email_address.blank? && updated_at < 24.hours.ago && !satisfied?
  end

  def is_eligible_to_resend?
    !email_address.blank? && !satisfied?
  end
end
