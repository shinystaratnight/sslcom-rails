class ApiDcvEmailResend < ApiCertificateRequest
  validates :account_key, :secret_key, :ref, presence: true
  validates :email_address, email: true, unless: lambda{|c|c.email_address.blank?}
  validates_presence_of  :order_exists, :verify_dcv_email_address, on: :create

  attr_accessor :certificate_order, :sent_at

  def order_exists
    errors[:email_address]<< "certificate order #{ref} does not exist" unless
        certificate_order=CertificateOrder.find_by_ref(ref)
  end


  def verify_dcv_email_address
    if self.email_address
      emails=ComodoApi.domain_control_email_choices(certificate_order.common_name).email_address_choices
      errors[:email_address]<< "must be one of the following: #{emails.join(", ")}" unless
          emails.include?(self.dcv_email_address)
    end
  end

end
