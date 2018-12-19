class ApiCertificateRequest < CaApiRequest
  include CertificateType
  attr_accessor :csr_obj, :current_user, :test, :action, :admin_submitted

  ORDER_STATUS = ["waiting for domain control validation",
                "waiting for documents", "pending validation", "validated", "issued", "revoked", "canceled"]

  PRODUCTS = Settings.api_product_codes.to_hash.stringify_keys

  NON_EV_SSL_PERIODS = %w(365 730 1095 1461 1826)
  EV_SSL_PERIODS = %w(365 730)
  EV_CS_PERIODS = %w(365 730 1095)
  FREE_PERIODS = %w(30 90)

  CREATE_ACCESSORS_1_4 = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_candidate_addresses, :dcv_method, :ref, :contacts, :options, :renewal_id, :billing_profile]

  UPDATE_ACCESSORS_1_4 = [:cert_names, :caa_check_domains]

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :domains, :options,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_candidate_addresses, :dcv_method, :dcv_methods, :certificate_ref, :contacts, :admin_funded,
      :ca_order_number, :debug, :api_call, :billing_profile, :callback, :unique_value]

  REPROCESS_ACCESSORS = [:account_key, :secret_key, :server_count, :server_software, :domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number,
      :dcv_methods, :ref, :options]

  RETRIEVE_ACCESSORS = [:account_key, :secret_key, :ref, :query_type, :response_type, :response_encoding,
    :show_validity_period, :show_domains, :show_ext_status, :validations, :registrant, :start, :end, :filter,
    :show_subscriber_agreement, :product_name, :search, :cert_results, :callback_hook]

  DETAILED_ACCESSORS = [:menu, :sub_main, :cert_details, :smart_seal, :id, :artifacts_status,
                        :publish_to_site_seal, :viewing_method, :publish_to_site_seal_approval, :is_admin]

  UPLOAD_ACCESSORS = [:checkout_in_progress, :is_dv, :is_dv_or_basic, :is_ev, :community_name, :all_domains,
                      :acceptable_file_types, :other_party_request, :subject, :validation_rules, :success_message]

  DCV_EMAIL_RESEND_ACCESSORS = [:account_key, :secret_key, :ref, :email_address]

  DCV_EMAILS_ACCESSORS = [:account_key, :secret_key, :domain]

  REVOKE_ACCESSORS = [:account_key, :secret_key, :ref, :reason, :serials]

  PRETEST_ACCESSOR = [:is_passed]

  # be sure to review wrap_parameters in ApiCertificateRequestsController when modifying attr_accessor below
  attr_accessor *(ACCESSORS+RETRIEVE_ACCESSORS+DCV_EMAILS_ACCESSORS+REVOKE_ACCESSORS+PRETEST_ACCESSOR+DETAILED_ACCESSORS+UPLOAD_ACCESSORS+UPDATE_ACCESSORS_1_4).uniq

  before_validation(on: :create) do
    ac=api_credential
    unless ac.blank?
      self.api_requestable = ac.ssl_account
    else
      errors[:login] << "account_key not found or wrong secret_key"
      false
    end
  end

  after_initialize do
    if new_record?
      self.ca ||= "ssl.com"
    end
  end

  def api_credential
    (self.account_key && self.secret_key) ?
        ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key) : nil
  end

  def find_certificate_order(field=:ref)
    # Rails.cache.clear
    if defined?(field) && self.send(field)
      if self.api_requestable.users.find_all(:active?).find(&:is_admin?)
        self.admin_submitted = true
        if co=CertificateOrder.find_by_ref(self.send(field))
          self.api_requestable = co.ssl_account
          co
        else
          errors[:certificate_order] << "Certificate order not found for ref #{self.send(field)}."
          nil
        end
      else
        self.api_requestable.certificate_orders.find_by_ref(self.send(field)) ||
          (errors[:certificate_order] << "Certificate order not found for ref #{self.send(field)}." ; nil)
      end
    end
  end

  # find signed certificates based on the `serials` api parameter
  def find_signed_certificates(certificate_order=nil)
    return nil if certificate_order.blank? && !self.admin_submitted
    klass = (self.admin_submitted && certificate_order.blank?) ? SignedCertificate.unscoped :
                certificate_order.signed_certificates
    certs = []
    ([]).tap do |certs|
      if defined?(:serials) && self.serials
        (self.serials.is_a?(Array) ? serials : [serials]).map do |serial|
          if sc=klass.find_by_serial(serial)
            certs<<sc
          else
            errors[:signed_certificate] <<
                "Signed certificate not found for serial #{serial}#{" within certificate order ref #{certificate_order.ref}" if certificate_order}."
            break
          end
        end
      else
        certs<<klass
      end
    end
  end

  # def find_certificate_orders(search,offset,limit)
  def find_certificate_orders(search,options={})
    is_test = self.test ? "is_test" : "not_test"
    co =
      # TODO if ApiCredential.roles include? Role.find(6) super_user
      if false # self.api_requestable.users.find(&:is_admin?)
        self.admin_submitted = true
        CertificateOrder.send(is_test)
      else
        self.api_requestable.certificate_orders.send(is_test)
      end
      # end.offset(offset).limit(limit)
    co = co.search_with_csr(search,options) if search
    if co
      self.filter=="vouchers" ? co.send("unused_credits") : co
    else
      (errors[:certificate_orders] << "Certificate orders not found.")
    end
  end

  def ref
    read_attribute(:ref) || @ref || JSON.parse(self.parameters)["ref"]
  end

  def validations_from_comodo(co) #if named 'validations', it's executed twice
    mdc_validation = ComodoApi.mdc_status(co)
    ds = mdc_validation.domain_status
    cc = co.certificate_content
    cns = co.certificate_names.includes(:domain_control_validations)
    dcvs = {}.tap do |dcv|
      (co.certificate.is_ucc? ? co.all_domains : [co.common_name]).each do |domain|
        last = (cns.find_all{|cn|cn.name==domain}).map(&:domain_control_validations).flatten.compact.last ||
          (co.csr.domain_control_validations.flatten.compact.last if (co.csr && co.csr.common_name==domain))
        unless last.blank?
          dcv.merge! domain=>{"attempted_on"=>last.created_at,
                              "dcv_method"=>(last.email_address || last.dcv_method),
                              "status"=>(ds && ds[domain]) ? ds[domain]["status"].downcase : "not yet available"}
        end
      end if co.all_domains
    end
    dcvs.blank? ? nil : dcvs #be consistent with the api results by returning null if empty
  end

  def retry
    %x"curl -k -H 'Accept: application/json' -H 'Content-type: application/json' -X #{request_method.upcase} -d '#{parameters}' #{request_url.gsub(".com",".local:3000").gsub("http:","https:")}"
  end

  def serial
    PRODUCTS[self.product.to_s] if product
  end

  def target_certificate
    @target_certificate ||=
      if serial
        Certificate.find_by_serial(serial)
      elsif ref
        CertificateOrder.unscoped.find_by_ref(ref).certificate
      end
  end

  %W(is_premium_ssl? is_dv_or_basic? is_basic? is_multi? is_document_signing? is_personal? is_wildcard?
      is_ucc? is_free? is_premium_ssl? is_evucc? is_wildcard?).each do |name|
    define_method(name) do
      target_certificate.send(name) if target_certificate
    end
  end
  alias_method "is_premium?".to_sym, "is_premium_ssl?".to_sym

  def is_not_ip
    true
  end
end
