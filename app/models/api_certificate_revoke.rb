class ApiCertificateRevoke < ApiCertificateRequest
  validates :account_key, :secret_key, :reason, presence: true
  validates :ref, presence: true
  validates_presence_of :signed_certificate_exists

  attr_accessor :reason, :domains, :ext_status, :certificates, :order_status, :certificate_order,
                :common_name, :subject_alternative_names, :effective_date, :expiration_date, :algorithm,
                :site_seal_code, :domains_qty_purchased, :wildcard_qty_purchased, :description, :subscriber_agreement,
                :order_date

  def signed_certificate_exists
      if self.ref
        self.signed_certificate=
            (self.api_requestable.certificate_orders.find_by_ref(self.ref) or
            self.api_requestable.certificate_contents.find_by_ref(self.ref)).signed_certificate
        errors[:ref] << "doesn't exist'" unless self.signed_certificate
      elsif self.serials
        self.signed_certificate=self.api_requestable.signed_certificates.find_by_serial(self.serials).last
        errors[:serials] << "doesn't exist'" unless self.signed_certificate
      end
      self.signed_certificate
  end

end
