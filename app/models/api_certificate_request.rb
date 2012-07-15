class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj, :current_user, :test

  ORDER_STATUS = ["waiting for domain control validation",
                "waiting for documents", "pending validation", "validated", "issued"]

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :other_domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_email_addresses, :dcv_method]

  RETRIEVE_ACCESSORS = [:account_key, :secret_key, :ref, :query_type, :response_type, :response_encoding,
    :show_validity_period, :show_domains, :show_ext_status]

  DCV_EMAILS_ACCESSORS = [:account_key, :secret_key, :domain_name]

  attr_accessor *(ACCESSORS+RETRIEVE_ACCESSORS+DCV_EMAILS_ACCESSORS).uniq

  before_validation(on: :create) do
    if self.account_key && self.secret_key
      ac=ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key)
      unless ac.blank?
        self.current_user = ac.ssl_account.users.last
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

end
