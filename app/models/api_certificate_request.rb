class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :other_domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_email_addresses, :dcv_method, :certificate_url, :receipt_url, :smart_seal_url, :validation_url,
      :order_number]

  RETRIEVE_ACCESSORS = [:account_key, :secret_key, :ref, :query_type, :response_type, :show_validity_period,
    :show_domains, :show_ext_status, :response_format]

  attr_accessor *(ACCESSORS+RETRIEVE_ACCESSORS).uniq
end
