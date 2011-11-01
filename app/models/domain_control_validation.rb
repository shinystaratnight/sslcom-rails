class DomainControlValidation < ActiveRecord::Base
  has_many :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to :csr
  serialize :candidate_addresses

  validate  :email_address_check, unless: lambda{|r| r.email_address.blank?}

  IS_INVALID  = "is an invalid email address choice"

  include Workflow
  workflow do
    state :new do
      event :send_dcv, :transitions_to => :sent_dcv
      event :satisfy, :transitions_to => :satisfied
    end

    state :sent_dcv do
      event :satisfy, :transitions_to => :satisfied

      on_entry do
        self.update_attribute :sent_at, DateTime.now
      end
    end

    state :satisfied do
      on_entry do
        self.update_attribute :responded_at, DateTime.now
      end
    end
  end

  def email_address_check
    errors.add(:email_address, "'#{email_address}' "+IS_INVALID) unless
      candidate_addresses.include?(email_address)
  end

  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now
    if csr.sent_success
      ComodoApi.resend_dcv(self)
      co=csr.certificate_content.certificate_order
      co.receipt_recipients.uniq.each do |c|
        OrderNotifier.dcv_sent(c, co, self).deliver!
      end
    end
  end

  def is_eligible_to_send?
    !email_address.blank? && updated_at < 24.hours.ago && !satisfied?
  end

  def is_eligible_to_resend?
    !email_address.blank? && !satisfied?
  end
end
