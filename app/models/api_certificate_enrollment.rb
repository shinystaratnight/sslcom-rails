class ApiCertificateEnrollment < ApiCertificateRequest
  include OrdersHelper

  validates :certificate_id, :duration, :domains, :account_key, :secret_key, :approver_id, presence: true

  def certificate_enrollment
    return false unless api_requestable
    
    @certificate = Certificate.find parameters_to_hash["certificate_id"]
    @domains = parse_domains(parameters_to_hash["domains"])
    
    enroll
    
    return true if @order && @order.persisted? && @order.valid?
  end

  def enroll
    # STEP 1: Setup Certificate Orders
    @certificate_orders = setup_certificate_orders
    
    # STEP 2: Setup Order
    setup_order

    # STEP 3: Add Certificate Orders to Order
    @order.add_certificate_orders(@certificate_orders)

    if @order.save
      # STEP 4: Paid status for Certificate Orders, Order is Invoiced
      pay_certificate_orders
      update_enrollment_request

      # STEP 5: Create Registrants
      setup_registrants unless iv_only?
      
      # STEP 6: Validate Individual Validations (via Delayed Job) 
      @order.smime_client_enrollment_validate(approver_id)
    end
  end

  private

  def setup_certificate_orders
    if @certificate
      @domains.inject([]) do |cos, email|
        co = CertificateOrder.new(
          has_csr: false,
          ssl_account: api_requestable,
          duration: parameters_to_hash["duration"]
        )
        co.certificate_contents << CertificateContent.new(domains: [])
        cos << Order.setup_certificate_order(
          certificate: @certificate,
          certificate_order: co
        )
        cos
      end
    else
      []
    end
  end

  def setup_order
    invoice_descr = require_emails_as_domains? ? "emails" : "domains"
    @order = EnrollmentOrder.new(
      state: "invoiced",
      approval: "approved",
      invoice_description: "Certificate enrollment for #{@certificate_orders.count} #{invoice_descr}.",
      description: Order::CERTIFICATE_ENROLLMENT,
      billable_id: @certificate_orders.first.ssl_account.try(:id),
      billable_type: "SslAccount",
      invoice_id: Invoice.get_or_create_for_team(api_requestable).try(:id),
    )
  end

  def pay_certificate_orders
    @order.cached_certificate_orders.update_all(
      ssl_account_id: api_requestable.try(:id), workflow_state: "paid"
    )
  end

  def update_enrollment_request
    req_id = parameters_to_hash["request_id"]
    if req_id
      req = api_requestable.certificate_enrollment_requests.find req_id
      req.update(
        order_id: @order.id,
        status: CertificateEnrollmentRequest::statuses[:approved]
      ) if req
    end
  end

  def setup_registrants
    registrant_params = api_requestable.epki_registrant.attributes
      .except(*%w{id created_at updated_at type domains roles})
      .merge({
        "parent_id" => api_requestable.epki_registrant.id,
        "status" => Contact::statuses[:validated]
      })
    ccs = CertificateContent.joins(certificate_order: :orders)
      .where(orders: {id: @order.id})
    ccs.each do |cc|
      cc.create_registrant(registrant_params)
      cc.create_locked_registrant(registrant_params)
      cc.save
    end
  end

  def require_emails_as_domains?
    @certificate.is_code_signing? || @certificate.is_smime_or_client?
  end

  def iv_only?
    @certificate.is_client_basic? || @certificate.is_client_pro?
  end

  def parse_domains(domains)
    if require_emails_as_domains?
      smime_client_parse_emails(domains)
    else
      @domains
    end  
  end
end
