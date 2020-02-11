module OrdersHelper

  def stats(unpaginated)
    if current_user.is_admin?
      # Invoiced orders
      invoice_items = unpaginated.where(state: 'invoiced')

      @payable_invoices = Invoice
                              .where.not(billable_id: nil, type: nil)
                              .where(id: invoice_items.pluck(:invoice_id).uniq).joins(:orders).includes(:orders)

      @pending_payable_invoices = @payable_invoices
                                      .where(status: 'pending')
                                      .where(orders: {approval: 'approved'})
                                      .map(&:orders).flatten.uniq
                                      .select{|o| invoice_items.include?(o)}.sum(&:cents)

      @paid_payable_invoices = @payable_invoices
                                   .where(status: ['paid', 'partially_refunded'])
                                   .where(orders: {approval: 'approved'})
                                   .map(&:orders).flatten.uniq
                                   .select{|o| invoice_items.include?(o)}.sum(&:cents)

      @refunded_payable_invoices = @payable_invoices
                                       .where(status: 'refunded')
                                       .where(orders: {approval: 'approved'})
                                       .map(&:orders).flatten.uniq
                                       .select{|o| invoice_items.include?(o)}.sum(&:cents)

      @partial_refunds_payable_invoices = @payable_invoices
                                              .where(status: 'partially_refunded')
                                              .where(orders: {approval: 'approved'})
                                              .map(&:payment).map(&:refunds).flatten.uniq.sum(&:amount)

      @paid_payable_invoices -= @partial_refunds_payable_invoices

      @payable_invoices_count = @payable_invoices.uniq.count
      @invoiced_orders_count = invoice_items.count

      # Non invoiced orders
      @negative = unpaginated
                      .where(state: %w{charged_back canceled rejected payment_not_required payment_declined})
                      .where.not(description: [Order::MI_PAYMENT, Order::DI_PAYMENT])  # exclude invoice payments (as order)
                      .where.not(state: 'invoiced')                    # exclude invoice items (as order)
                      .sum(:cents)

      refunded = Refund.where(
          order_id: unpaginated
                        .where.not(description: [Order::MI_PAYMENT, Order::DI_PAYMENT])
                        .where.not(state: 'invoiced')
                        .where(state: ['partially_refunded', 'fully_refunded']).map(&:id)
      ).where(status: 'success')

      deposits = unpaginated.joins{ line_items.sellable(Deposit) }

      orders = unpaginated.where.not(id: deposits.map(&:id))
                   .where.not(description: [Order::MI_PAYMENT, Order::DI_PAYMENT])
                   .where.not(state: 'invoiced')

      # Funded Account Withdrawal
      faw = unpaginated.where(description: Order::FAW).sum(:cents)

      deposits = deposits.where.not(description: Order::FAW)

      @refunded_amount = refunded.sum(:amount)
      @refunded_count  = refunded.count
      @deposits_amount = deposits.sum(:cents)
      @deposits_count  = deposits.count
      @total_amount    = orders.sum(:cents) - @negative - @refunded_amount - faw
      @total_count     = orders.count
    end
  end

  def cart_items
    if current_user && current_user.ssl_account.has_role?('new_reseller') && current_user.ssl_account.reseller
      return [current_user.ssl_account.reseller.reseller_tier]
    elsif !@certificate_order.blank?
      return [@certificate_order]
    elsif !@certificate_orders.blank?
      certs=[]
      @certificate_orders.each do |cert|
        cert.quantity.times do
          certs<<cert
        end
      end
      return certs
    elsif @funded_account
      return []
    end
    [] #use cart_products if products expand beyond certs
  end

  def cart_items_count
    items=cart_contents.reject{|c|c and c[ShoppingCart::PRODUCT_CODE]=~/\Areseller_tier/}
    current_user ? items.select{|i|current_user.ssl_account.can_buy?(i)}.count : items.count
  end

  def current_order
    order = current_user.nil? ? User.new.ssl_accounts.build.purchase(*cart_items) :
      current_user.ssl_account.purchase(*cart_items)
    order.cents = cart_items.inject(0){|result, element| result +
        element.attributes_before_type_cast["amount"].to_f}
    order
  end

  def domains_adjustment_order
    if current_user
      amount       = Money.new(params[:order_amount].to_f * 100)
      @ssl_account = @certificate_order.ssl_account
      order        = @ssl_account.purchase(@certificate_order)
      order.amount = amount
      order.cents  = amount.cents
      order.invoice_description = params[:order_description]
      order
    end
  end

  def current_order_reprocess_ucc
    if current_user
      @ssl_account = @certificate_order.ssl_account
      order        = @ssl_account.purchase(@certificate_order)
      order.cents  = @certificate_order.ucc_prorated_amount(@certificate_content, @tier)
      order.amount = Money.new(order.cents)
      order.type   = "ReprocessCertificateOrder"
      order
    end
  end

  def is_current_order_affordable?
    current_user.ssl_account.funded_account.amount.cents >=
      current_order.amount.cents
  end

  def cart_total_price
    Money.new(cart_items.sum(&:amount)).format :with_currency => true
  end

  def min_cart_item_price
    Money.new(cart_items.minimum(&:amount)).format :with_currency => true
  end

  def max_cart_item_price
    Money.new(cart_items.maximum(&:amount)).format :with_currency => true
  end

  def avg_cart_item_price
    Money.new(cart_items.average(&:amount)).format :with_currency => true
  end

  def link_to_checkout
    if cart_items.size > 0 and logged_in? and !current_user.funded_account.blank? and (current_user.funded_account.amount.cents >= current_order.amount.cents)
      link_to "Checkout", confirm_funds_path
    elsif cart_items.size > 0
      link_to "Checkout", allocate_funds_for_order_path
    end
  end

  def apply_order
    (@order.cents > 0 or @order.is_free?) and @funded_account.deduct_order?
  end

  def display_line_items(order, formatted=true)
    content_tag("div", order.line_items.inject("") {|str, line_item|
      str << content_tag("div", "#{line_item.sellable.class.to_s} -
        #{line_item.sellable.description.shorten(20,false)}",
        :class => "line_item_receipt")}, :class=> "line_items_receipt")
  end

  def is_cart_empty?
    cart_items.size==0
  end

  def new_order_title(certificate=nil)
    "Checkout #{' And Subscriber Agreement' if certificate}"
  end

  def ssl_account
    current_user.try(:ssl_account)
  end

  def reseller_initial_deposit?
      return false if ssl_account.reseller.blank?
      ssl_account.reseller.enter_billing_information? || ssl_account.reseller.select_tier?
  end

  def reseller_tier_is_free?
    ssl_account.reseller.reseller_tier.try(:amount) <=0
  end

  def is_receipt?
    (@deposit && @deposit.receipt) || (@order && @order.receipt)
  end

  def determine_eligibility_to_buy(certificate, certificate_order)
    unless current_user.blank?
      current_user.ssl_account.clear_new_certificate_orders
      unless current_user.ssl_account.can_buy?(certificate)
        flash.now[:error] = "Certificate belongs to a pricing tier which differs
          from your reseller tier level"
        return render(:template => "submit_csr", :layout=>"application")
      else
        certificate_order.ssl_account = current_user.ssl_account
      end
    end
  end

  def url_to_new_order
    url = @certificate_orders ? create_multi_free_ssl_orders_path : create_free_ssl_orders_path
    [Order.new]+ (is_order_free? ? [{url: url}] : [])
  end

  def is_order_free?
    current_order.amount.to_s.to_i<=0
  end

  def confirm_affiliate_sale
    # @order.reload
    if !@order.domains_adjustment? && !@order.invoice_payment? && !@order.on_payable_invoice?
        !@order.ext_affiliate_credited? && (@order.persisted? ? @order.created_at > 1.minute.ago : true )
      @order.toggle! :ext_affiliate_credited
      if @order.ext_affiliate_name=="shareasale"
        "<img src=\"https://shareasale.com/sale.cfm?amount=#{@order.final_amount.to_s}&tracking=#{@order.reference_number}&transtype=sale&merchantID=#{@order.ext_affiliate_id}\" width=\"1\" height=\"1\">".html_safe
      else
        "<img border=\"0\" src=\"https://#{Settings.community_domain}/affiliate/sale.php?profile=#{@order.ext_affiliate_id}&idev_saleamt=#{@order.final_amount.to_s}&idev_ordernum=#{@order.reference_number}#{"&coupon_code="+@order.discounts.last.ref unless @order.discounts.empty?}\" width=\"1\" height=\"1\">".html_safe
      end if @order.amount.cents > 0
    end
  end

  def row_description(order)
    if order.is_a?(CertificateOrder)
      order.respond_to?(:description_with_tier) ? order.description_with_tier(@order) :
          certificate_type(order)
    elsif order.is_a?(ProductOrder)
      order.product.title
    else
      order.class.name
    end
  end

  def log_declined_transaction(transaction, last_four)
    unless current_user.nil?
      fa       = current_user.ssl_account.funded_account
      declined = fa.card_recently_declined?
      cards    = declined ? fa.card_declined[:cards] : []
      fa.update(card_declined: nil) unless declined
      if transaction && transaction.message.include?('This transaction has been declined')
        fa.update(
          card_declined: {
            order_transaction_id: transaction.try(:id),
            user_id:              current_user.try(:id),
            cards:                cards.push(last_four),
            declined_at:          DateTime.now,
            controller:           "#{controller_name}##{action_name}",
          }
        )
        fa.delay_transaction
      end
    end
  end

  def test_label(order)
    unless order.display_state.blank?
      order.display_state+" "
    else
      order.is_test? ? "(TEST) " : ""
    end
  end

  def delay_transaction?
    fa       = current_user.ssl_account.funded_account if current_user
    declined = fa && fa.card_recently_declined? if fa
    next_try = fa.card_declined[:next_attempt] if declined
    cards    = fa.card_declined[:cards] if declined
    return false if !declined || (declined && cards && cards.any? && cards.count < 2)
    declined && next_try && (next_try > DateTime.now)
  end

  def order_invoice_notes
    "Payment for #{@invoice.get_type_format.downcase} invoice total of #{@invoice.get_amount_format} due on #{@invoice.end_date.strftime('%F')}."
  end

  def ucc_csr_submit_notes
    "Initial CSR submit, UCC domains adjustment (certificate order: #{@certificate_order.ref}, certificate content: #{@certificate_content.ref})"
  end

  def renew_ucc_notes
    "Renewal UCC domains adjustment (certificate order: #{@certificate_order.ref}, certificate content: #{@certificate_content.ref})"
  end

  def reprocess_ucc_notes
    "Reprocess UCC (certificate order: #{@certificate_order.ref}, certificate content: #{@certificate_content.ref})"
  end

  def smime_client_enrollment_notes(emails_count=nil)
    "S/MIME or Client enrollment for #{emails_count} emails."
  end

  def ucc_or_invoice_params
    order = params[:order] || params[:smime_client_enrollment_order]

    unless @payable_invoice
      @ssl_account = if current_user.is_system_admins?
        CertificateOrder.find_by(ref: params[:order][:co_ref]).ssl_account
      else
        current_user.ssl_account
      end
    end

    unless params[:funding_source].nil? ||
      (params[:funding_source] && params[:funding_source] == 'paypal')
      existing_card = @ssl_account.billing_profiles.find(params[:funding_source])
    end

    @funded_amount       = order[:funded_amount].to_f
    @order_amount        = order[:order_amount].to_f
    @charge_amount       = order[:charge_amount].to_f
    @too_many_declines   = delay_transaction? && (params[:payment_method] == 'credit_card')
    @billing_profile     = BillingProfile.new(params[:billing_profile]) if params[:billing_profile]
    @profile             = existing_card || @billing_profile
    @credit_card         = @profile.build_credit_card
    @funded_account_init = @ssl_account.funded_account.cents
    @target_amount       = (@charge_amount.blank? || @charge_amount == 0) ? @order_amount : @charge_amount

    if @reprocess_ucc || @renew_ucc || @ucc_csr_submit
      @certificate_order   = @ssl_account.cached_certificate_orders.find_by(ref: order[:co_ref])
      @certificate_content = @certificate_order.certificate_contents.find_by(ref: order[:cc_ref])
    end
  end

  def withdraw_funded_account(credit_amount, full_amount=0)
    @order.save unless @order.persisted?
    order_amount = @order_amount || full_amount
    fully_covered = credit_amount >= (order_amount * 100).to_i
    full_amount = fully_covered ? @order.amount.format : Money.new(@order.cents + credit_amount).format
    notes = "#{fully_covered ? 'Full' : 'Partial'} payment for order ##{@order.reference_number} (#{full_amount}) "
    notes << "for UCC certificate reprocess." if @reprocess_ucc
    notes << "for renewal UCC domains adjustment." if @renew_ucc
    notes << "for initial CSR submit UCC domains adjustment." if @ucc_csr_submit
    notes << "for #{@invoice.get_type_format.downcase} invoice ##{@invoice.reference_number}." if @payable_invoice

    fund = Deposit.create(
      amount:         credit_amount,
      full_name:      "Team #{@ssl_account.get_team_name} funded account",
      credit_card:    'N/A',
      last_digits:    'N/A',
      payment_method: 'Funded Account'
    )

    @funded = @ssl_account.purchase fund
    @funded.description = 'Funded Account Withdrawal'
    @funded.notes = notes
    @funded.save
    @funded.mark_paid!
    @ssl_account.funded_account.decrement! :cents, credit_amount
    @ssl_account.funded_account.save
  end

  def get_order_notes
    return reprocess_ucc_notes if @reprocess_ucc
    return order_invoice_notes if @payable_invoice
    return renew_ucc_notes if @renew_ucc
    return ucc_csr_submit_notes if @ucc_csr_submit
    return smime_client_enrollment_notes('') if @order.is_a?SmimeClientEnrollmentOrder
    ''
  end

  def get_order_descriptions
    return Order::DOMAINS_ADJUSTMENT if @reprocess_ucc || @renew_ucc || @ucc_csr_submit
    return (@ssl_account.get_invoice_pmt_description) if @payable_invoice
    return Order::S_OR_C_ENROLLMENT if @order.is_a?SmimeClientEnrollmentOrder
    Order::SSL_CERTIFICATE
  end

  def ucc_update_domain_counts
    co = @certificate_order
    notes = []
    order = params[:order]
    reseller_tier = @tier || find_tier

    # domains entered
    wildcard = order ? order[:wildcard_count].to_i : params[:wildcard_count].to_i
    nonwildcard = order ? order[:nonwildcard_count].to_i : params[:nonwildcard_count].to_i

    # max domain counts stored
    co_nonwildcard = co.nonwildcard_count.blank? ? 0 : co.nonwildcard_count
    co_wildcard = co.wildcard_count.blank? ? 0 : co.wildcard_count

    # max for previous signed certificates to determine credited domains
    prev_wildcard    = co.get_reprocess_max_wildcard(co.certificate_content).count
    prev_nonwildcard = co.get_reprocess_max_nonwildcard(co.certificate_content).count

    if (co_nonwildcard > prev_nonwildcard) &&
      ((nonwildcard > co_nonwildcard) || (@reprocess_ucc &&
      (nonwildcard >= co_nonwildcard && (nonwildcard > 0))))
      notes << "#{co_nonwildcard - prev_nonwildcard} non wildcard domains"
    end

    if (co_wildcard > prev_wildcard) &&
      ((wildcard > co_wildcard) || (@reprocess_ucc &&
      (wildcard >= co_wildcard && (wildcard > 0))))
      notes << "#{co_wildcard - prev_wildcard} wildcard domains"
    end

    # record new max counts
    new_nonwildcard = nonwildcard > co_nonwildcard ? nonwildcard : co_nonwildcard
    new_wildcard = wildcard > co_wildcard ? wildcard : co_wildcard
    co.update( nonwildcard_count: new_nonwildcard, wildcard_count: new_wildcard )
    @order.max_non_wildcard = new_nonwildcard
    @order.max_wildcard = new_wildcard

    if reseller_tier
      @order.reseller_tier_id = ResellerTier.find_by(label: find_tier.delete('tr')).try(:id)
    end

    if notes.any?
      @order.invoice_description = '' if @order.invoice_description.nil?
      @order.invoice_description << " Received credit for #{notes.join(' and ')}."
    end
    @order.lock!
    @order.save
  end

  def purchase_successful?
    return false unless (ActiveMerchant::Billing::Base.mode == :test ? true : @credit_card.valid?)

    @order.description = get_order_descriptions

    other_order = @reprocess_ucc || @renew_ucc || @payable_invoice

    options = @profile.build_info(@order.description.gsub('Payment', 'Pmt')).merge(
      stripe_card_token: params[:billing_profile][:stripe_card_token],
      owner_email: current_user.nil? ? params[:user][:email] : current_user.ssl_account.get_account_owner.email
    )
    options.merge!(amount: (@target_amount.to_f * 100).to_i) if other_order

    @gateway_response = @order.purchase(@credit_card, options)
    log_declined_transaction(@gateway_response, @credit_card.number.last(4)) unless @gateway_response.success?
    (@gateway_response.success?).tap do |success|
      if success
        flash.now[:notice] = @gateway_response.message
        @order.mark_paid!
        # in case the discount becomes invalid before check out, give it to the customer
        unless other_order
          @order.discounts.each do |discount|
            Discount.decrement_counter(:remaining, discount) unless discount.remaining.blank?
          end
        end
        SystemAudit.create(
          owner:  current_user,
          target: @order,
          action: "purchase successful",
          notes:  get_order_notes
        )
      elsif @order.invoiced?
        flash[:notice] = "Order has been added to invoice due to transaction failure. #{@gateway_response.message}"
        SystemAudit.create(
          owner:  current_user,
          target: @order,
          action: "order added to invoice due to denied transaction",
          notes: @gateway_response.message
        )
        return true
      else
        flash.now[:error] = if @gateway_response.message=~/no match/i
          "CVV code does not match"
        else
          @gateway_response.message #no descriptive enough
        end
        @order.transaction_declined!
        unless other_order
          @certificate_order.destroy unless @certificate_order.blank?
        end
      end
    end
  end

  def order_reqs_valid?
    @order.valid? && (params[:funding_source] ? @profile.valid? :
      @billing_profile.valid?) && (current_user || @user.valid?)
  end

  # ============================================================================
  # S/MIME OR CLIENT ENROLLMENT ORDER
  # ============================================================================
  def smime_client_parse_emails(emails=nil)
    emails_list = emails || params[:emails]
    if emails_list.is_a? Array
      @emails = emails_list
    else
      unless emails_list.strip.blank?
        @emails = emails_list
          .strip.split(/[\s,]+/).map(&:strip).map(&:downcase)
        @emails.select {|e| e =~ URI::MailTo::EMAIL_REGEXP}
      end
    end
  end

  def smime_client_enrollment_co_paid
    @order.cached_certificate_orders.update_all(
      ssl_account_id: @ssl_account.try(:id), workflow_state: 'paid'
    )
  end

  def smime_client_enrollment_registrants
    registrant_params = @ssl_account.epki_registrant.attributes
      .except(*%w{id created_at updated_at type domains roles})
      .merge({
        'parent_id' => @ssl_account.epki_registrant.id,
        'status' => Contact::statuses[:validated]
      })
    ccs = CertificateContent.joins(certificate_order: :orders)
      .where(orders: {id: @order.id})
    ccs.each do |cc|
      cc.create_registrant(registrant_params)
      cc.create_locked_registrant(registrant_params)
      cc.save
    end
  end

  def smime_client_enrollment_validate
    if current_user && @order && @order.persisted?
      @order.smime_client_enrollment_validate(current_user.id)
    end
  end

  def smime_client_enrollment_items
    if @certificate
      @emails.inject([]) do |cos, email|
        co = CertificateOrder.new(
          has_csr: false, ssl_account: @ssl_account, duration: params[:duration]
        )
        co.certificate_contents << CertificateContent.new(domains: [email])
        cos << Order.setup_certificate_order(
          certificate: @certificate, certificate_order: co
        )
        cos
      end
    else
      []
    end
  end

=begin
  def setup_certificate_order
    #adjusting duration to reflect number of days validity
    duration = @certificate_order.duration.to_i * 365
    @certificate_order.certificate_contents[0].duration = duration
    if @certificate.is_ucc? || @certificate.is_wildcard?
      psl = @certificate.items_by_server_licenses.find{|item|
        item.value==duration.to_s}
      so = SubOrderItem.new(:product_variant_item=>psl,
        :quantity=>@certificate_order.server_licenses.to_i,
        :amount=>psl.amount*@certificate_order.server_licenses.to_i)
      @certificate_order.sub_order_items << so
      if @certificate.is_ucc?
        pd = @certificate.items_by_domains.find_all{|item|
          item.value==duration.to_s}
        additional_domains = (@certificate_order.certificate_contents[0].
          domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so = SubOrderItem.new(:product_variant_item=>pd[0],
          :quantity=>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
          :amount=>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        @certificate_order.sub_order_items << so
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
            :quantity=>additional_domains,
            :amount=>pd[1].amount*additional_domains)
          @certificate_order.sub_order_items << so
        end
      end
    end
    unless @certificate.is_ucc?
      pvi = @certificate.items_by_duration.find{|item|item.value==duration.to_s}
      so = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
        :amount=>pvi.amount)
      @certificate_order.sub_order_items << so
    end
    @certificate_order.amount = @certificate_order.sub_order_items.map(&:amount).sum
    @certificate_order.certificate_contents[0].
      certificate_order = @certificate_order
  end
=end
end
