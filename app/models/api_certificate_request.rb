class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj, :current_user, :test, :action, :admin_submitted

  ORDER_STATUS = ["waiting for domain control validation",
                "waiting for documents", "pending validation", "validated", "issued", "revoked", "canceled"]

  CREATE_ACCESSORS_1_4 = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_email_addresses, :dcv_method, :ref, :contacts]

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_email_addresses, :dcv_method, :dcv_methods, :certificate_ref, :contacts, :admin_funded]

  REPROCESS_ACCESSORS = [:account_key, :secret_key, :server_count, :server_software, :domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_methods, :ref]

  RETRIEVE_ACCESSORS = [:account_key, :secret_key, :ref, :query_type, :response_type, :response_encoding,
    :show_validity_period, :show_domains, :show_ext_status]

  DCV_EMAIL_RESEND_ACCESSORS = [:account_key, :secret_key, :ref, :email_address]

  DCV_EMAILS_ACCESSORS = [:account_key, :secret_key, :domain_name, :domain_names]

  attr_accessor *(ACCESSORS+RETRIEVE_ACCESSORS+DCV_EMAILS_ACCESSORS).uniq

  before_validation(on: :create) do
    if self.account_key && self.secret_key
      ac=ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key)
      unless ac.blank?
        self.api_requestable = ac.ssl_account
      else
        errors[:login] << "account_key not found or wrong secret_key"
      end
    end
  end

  after_initialize do
    if new_record?
      self.ca ||= "ssl.com"
    end
  end

  def find_certificate_order
    if defined?(:ref) && self.ref
      if self.api_requestable.users.find(&:is_admin?)
        if co=CertificateOrder.find_by_ref(self.ref)
          self.api_requestable = co.ssl_account
          co
        else
          errors[:certificate_order] << "Certificate order not found for ref #{self.ref}."
        end
      else
        self.api_requestable.certificate_orders.find_by_ref(self.ref) || errors[:certificate_order] << "Certificate order not found for ref #{self.ref}."
      end
    end
  end
end
