class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj

  NON_EV_PERIODS = %w(365 730 1095 1461 1826)
  EV_PERIODS = %w(365 730)

  PRODUCTS = {:"100"=> "evucc256sslcom", :"101"=>"ucc256sslcom", :"102"=>"ev256sslcom",
              :"103"=>"ov256sslcom", :"104"=>"dv256sslcom", :"105"=>"wc256sslcom"}

  validates :account_key, :secret_key, :csr, :csr_obj, presence: true
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateRequest::NON_EV_PERIODS,
    message: "needs to one of the following: #{NON_EV_PERIODS.join(', ')}"}, if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateRequest::EV_PERIODS,
    message: "needs to one of the following: #{EV_PERIODS.join(', ')}"}, if: lambda{|c|c.is_ev?}
  validates :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.pluck(:id).map(&:to_s),
      message: "needs to one of the following: #{ServerSoftware.pluck(:id).map(&:to_s).join(', ')}"}
  validates :domain, :other_domains, presence: false, if: lambda{|c|!c.is_ucc?}
  validates :organization_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.organization.blank?}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"}, if: lambda{|c|!c.is_dv? && c.street_address_1.blank?} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"}, if: lambda{|c|!c.is_dv? && c.post_office_box.blank?} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.locality.blank?}
  validates :state_or_province_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.state.blank?}
  validates :postal_code, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country_name, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c|c.csr_obj && c.csr_obj.country.try("blank?")}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_email_address, email: true, unless: lambda{|c|c.dcv_email_address.blank?}
  validates :email_address, email: true, unless: lambda{|c|c.email_address.blank?}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validates :product, presence: true, format: {with: /\d{3}/},
            inclusion: {in: PRODUCTS.keys.map(&:to_s)}
  validates :is_customer_validated, format: {with: /(y|n|yes|no|true|false|1|0)/i}
  validates :is_customer_validated, presence: true, unless: lambda{|c|c.is_dv? && c.csr_obj.is_intranet?}
  #validate  :common_name, :is_not_ip, if: lambda{|c|!c.is_dv?}

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :other_domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number]

  attr_accessor *ACCESSORS

  after_initialize do
    if new_record? && self.csr
      self.csr_obj = Csr.new(body: self.csr)
      unless self.csr_obj.errors.empty?
        self.errors[:csr] << "has problems and or errors"
      end
    end
  end

  def self.apply_for_certificate(certificate)

  end

  def create_certificate_order
    # identify user and reseller tier
    current_user = User.find_by_login "rabbit"

    # create certificate
    @certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_sym])
    certificate_order = CertificateOrder.new(duration: period)
    certificate_content=certificate_order.certificate_contents.build(
        csr: self.csr_obj, server_software_id: self.server_software)
    certificate_content.certificate_order = certificate_order
    @certificate_order = setup_certificate_order(@certificate, certificate_order)
    certificate_content.valid?
    respond_to do |format|
      if @certificate_order.save
        if is_reseller? && (current_order.amount.cents >
              current_user.ssl_account.funded_account.amount.cents)
          format.html {redirect_to allocate_funds_for_order_path(:id=>
                'certificate')}
        else
          format.html {redirect_to confirm_funds_path(:id=>'certificate_order')}
        end
      else
        format.html { render(:template => "certificates/buy")}
      end
    end
  end

  def setup_certificate_order(certificate, certificate_order)
    duration = self.period
    certificate_order.certificate_content.duration = duration
    if certificate.is_ucc? || certificate.is_wildcard?
      psl = certificate.items_by_server_licenses.find { |item|
        item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>psl,
       :quantity            =>certificate_order.server_licenses.to_i,
       :amount              =>psl.amount*certificate_order.server_licenses.to_i)
      certificate_order.sub_order_items << so
      if certificate.is_ucc?
        pd                 = certificate.items_by_domains.find_all { |item|
          item.value==duration.to_s }
        additional_domains = (certificate_order.certificate_contents[0].
            domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so                 = SubOrderItem.new(:product_variant_item=>pd[0],
                                              :quantity            =>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                              :amount              =>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        certificate_order.sub_order_items << so
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
          certificate_order.sub_order_items << so
        end
      end
    end
    unless certificate.is_ucc?
      pvi = certificate.items_by_duration.find { |item| item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
                             :amount              =>pvi.amount)
      certificate_order.sub_order_items << so
    end
    certificate_order.amount = certificate_order.
        sub_order_items.map(&:amount).sum
    certificate_order.certificate_contents[0].
        certificate_order    = certificate_order
    certificate_order
  end

  def apply_funds
    @account_total = @funded_account = current_user.ssl_account.funded_account
    @funded_account.cents -= @order.cents unless @funded_account.blank?
    respond_to do |format|
      if @funded_account.cents >= 0 and @order.line_items.size > 0
        @funded_account.deduct_order = true
        if @order.cents > 0
          @order.save
          @order.mark_paid!
        end
        @funded_account.save
        flash.now[:notice] = "The transaction was successful."
        if @certificate_order
          @certificate_order.pay! true
          return redirect_to edit_certificate_order_path(@certificate_order)
        elsif @certificate_orders
          current_user.ssl_account.orders << @order
          clear_cart
          flash[:notice] = "Order successfully placed. %s"
          flash[:notice_item] = "Click here to finish processing your
            ssl.com certificates.", credits_certificate_orders_path
          format.html { redirect_to @order }
        end
        format.html { render :action => "success" }
      else
        if @order.line_items.size == 0
          flash.now[:error] = "Cart is currently empty"
        elsif @funded_account.cents <= 0
          flash.now[:error] = "There is insufficient funds in your SSL account"
        end
        format.html { render :action => "confirm_funds" }
      end
    end
  end

  def serial
    PRODUCTS[self.product.to_sym] if product
  end

  def is_ev?
    serial =~ /ev/ if serial
  end

  def is_dv?
    serial =~ /dv/ if serial
  end

  def is_wildcard?
    serial =~ /ucc/ if serial
  end

  def is_ucc?
    serial =~ /ucc/ if serial
  end

  def is_not_ip
    true
  end

end
