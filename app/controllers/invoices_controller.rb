class InvoicesController < ApplicationController
  include OrdersHelper
  
  before_filter :find_ssl_account, except: :index
  before_filter :set_ssl_slug, except: :index
  before_filter :find_invoice, except: :index
  
  filter_access_to :all
  filter_access_to :show, :update_invoice
  
  def index
    @invoices = invoices_base_query
    @invoices = @invoices.index_filter(params) if params[:commit]
    @invoices = @invoices.paginate(page: params[:page], per_page: 25)
  end
  
  def download
    if @invoice
      render pdf: "ssl.com_#{@ssl_account.get_invoice_label}_invoice_#{@invoice.reference_number}"
    else
      flash[:error] = "This invoice doesn't exist."
      redirect_to :back
    end
  end
  
  def show
    @order = @invoice.payment unless @invoice.nil? || @invoice.payment.nil?
  end
  
  def manage_items
    
  end
  
  def transfer_items
    orders = @invoice.orders.where(reference_number: params[:orders].split(','))
    orders_count = orders.count
    if orders_count > 0
      invoice = if params[:invoice] == 'new_invoice'
        Invoice.create_invoice_for_team(@invoice.billable.id)
      else
        Invoice.find_by(reference_number: params[:invoice])
      end
      orders.update_all(invoice_id: invoice.id)
      @invoice.destroy unless @invoice.orders.any?
      flash[:notice] = "All #{orders_count} order(s) have been successfully transferred to invoice ##{invoice.reference_number}."
      redirect_to invoice_path(@ssl_slug, invoice.reference_number)
    else
      flash[:error] = "Please select at least one order!"
      redirect_to manage_items_invoice_path(@ssl_slug, @invoice.reference_number)
    end
  end
  
  def edit
  end
  
  def update
    @invoice.update(params[:invoice]) if @invoice && params[:invoice]
    respond_to do |format|
      if @invoice.errors.any?
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      else
        format.json { render json: @invoice, status: :ok }
      end
    end
  end
  
  def new_payment
    @payable_invoice = true
  end
  
  def make_payment
    @payable_invoice = true
    ucc_or_invoice_params
    
    @order = Order.new(
      billing_profile_id: params[:funding_source],
      amount:             @target_amount,
      cents:              (@target_amount * 100).to_i,
      description:        @ssl_account.get_invoice_pmt_description,
      state:              'pending',
      approval:           'approved',
      notes:              order_invoice_notes
    )
    @order.billable = @ssl_account
    @order.save
    
    if @funded_amount > 0 && (@order_amount <= @funded_amount)
      # All amount covered by credit from funded account
      payment_funded_account
    else
      # Pay full or partial payment by CC or Paypal
      payment_hybrid
    end
  end
  
  def credit
    amount = params[:invoice][:amount].to_f

    if @invoice && !@invoice.refunded? && amount > 0
      payment        = @invoice.payment
      max            = @invoice.max_credit.to_s.to_f
      amount         = max if max <= amount
      imvoice_amount = @invoice.get_amount.to_s.to_f
      refunds        = Money.new(@invoice.get_merchant_refunds).to_s.to_f
      f_amount       = Money.new(amount*100).format
      
      if amount > 0
        @invoice.billable.funded_account.add_cents(amount*100)
        if (amount == imvoice_amount) || ((amount + refunds) == imvoice_amount)
          @invoice.full_refund!
          payment.full_refund! unless payment.fully_refunded?
        else
          @invoice.partial_refund!
        end
          
        SystemAudit.create(
          owner:  current_user,
          target: @invoice,
          notes:  "Credit issued with reason: #{params[:invoice][:credit_reason]}",
          action: "#{@ssl_account.get_invoice_label.capitalize} Invoice ##{@invoice.reference_number}, credit issued for #{f_amount}."
        )
      end
      flash[:notice] = "Invoice was successfully credited for amount #{f_amount}."
    else
      flash[:error] = "This invoice cannot be credited."
    end
    redirect_to_invoice
  end
  
  def refund_other
    if @invoice && !@invoice.refunded?
      payment = @invoice.payment
      payment_type = Invoice::PAYMENT_METHODS_TEXT[params[:refund_type].to_sym]
      @invoice.full_refund!
      payment.full_refund! unless payment.fully_refunded?
      SystemAudit.create(
        owner:  current_user,
        target: @invoice,
        notes:  "Full refund issued for payment type #{payment_type}.",
        action: "#{@ssl_account.get_invoice_label.capitalize} Invoice ##{@invoice.reference_number}, refund issued for #{payment.amount.format}."
      )
      flash[:notice] = "Invoice was successfully refunded for payment type #{payment_type}."
    else
      flash[:error] = "This invoice is already refunded."
    end
    redirect_to_invoice
  end
  
  def remove_item
    if @invoice && !@invoice.paid?
      o = @invoice.orders.find_by(reference_number: params[:item_ref])
      o.update(approval: 'rejected')
      flash[:notice] = "Item #{o.reference_number} has been removed from invoice."
    else
      flash[:error] = "Something went wrong or invoice has already been paid."
    end
    redirect_to_invoice
  end
  
  def add_item
    if @invoice && !@invoice.paid?
      o = @invoice.orders.find_by(reference_number: params[:item_ref])
      o.update(approval: 'approved')
      flash[:notice] = "Item #{o.reference_number} has been added back to invoice."
    else
      flash[:error] = "Something went wrong or invoice has already been paid."
    end
    redirect_to_invoice
  end
  
  def update_item
    if @invoice
      o = @invoice.orders.find_by(reference_number: params[:item_ref])
      if o
        o.update(invoice_description: params[:item_description]) unless params[:item_description].blank?
        flash[:notice] = "Item #{o.reference_number} description has been updated."
      end
    else
      flash[:error] = "Something went wrong, please try again."
    end
    redirect_to_invoice
  end
  
  def make_payment_other
    pmt_type = Invoice::PAYMENT_METHODS_TEXT[params[:ptm_type].to_sym]
    if @invoice && !@invoice.paid?
      @order = Order.new(
        amount:      @invoice.get_amount,
        cents:       @invoice.get_cents,
        description: @ssl_account.get_invoice_pmt_description,
        state:       'paid',
        approval:    'approved',
        notes:       order_invoice_notes << " Paid full amount of #{@invoice.get_amount_format} by #{pmt_type}."
      )
      @order.billable = @ssl_account
      @order.save
      
      if @order.persisted? && @invoice.update(status: 'paid', order_id: @order.id)
        flash[:notice] = "Paid full amount of #{@invoice.get_amount_format} by #{pmt_type}."
      else
        @order.destroy
        flash[:error] = "Something went wrong, please try again."
      end
    else
      flash[:error] = "Invoice was already paid off."
    end
    redirect_to_invoice
  end
  
  def destroy
    if @invoice
      if @invoice.archive!
          flash[:notice] = "Invoice #{@invoice.reference_number} successfully deleted."
      else
        flash[:error] = "Something went wrong, please try again!"
        redirect_to_invoice
      end
    end
    redirect_to_invoice
  end
    
  private
  
  def invoices_base_query
    base = if current_user.is_system_admins?
      (@ssl_account.try(:invoices) ? Invoice.unscoped{@ssl_account.try(:invoices).where.not(status: 'archived')} :
           Invoice.where.not(billable_id: nil, type: nil))
    else
      current_user.ssl_account.invoices.where.not(status: 'archived')
    end
    base.includes(:orders).uniq.sort_with(params)
  end
  
  def payment_hybrid
    if current_user && order_reqs_valid? && !@too_many_declines && purchase_successful?
      save_billing_profile unless (params[:funding_source])
      @order.billing_profile = @profile
      @order.save
      withdraw_funded_account((@funded_amount * 100).to_i) if @funded_amount > 0
      invoice_paid
      record_order_visit(@order)
      
      flash[:notice] = "Succesfully paid for invoice #{@invoice.reference_number}."
      redirect_to_invoice
    else
      flash[:error] = if @too_many_declines
        'Too many failed attempts, please wait 1 minute to try again!'
      else
        @gateway_response.message
      end
      redirect_new_payment
    end
    rescue Payment::AuthorizationError => error
      flash[:error] = error.message
      redirect_new_payment
  end
  
  def payment_funded_account
    withdraw_amount     = @order_amount < @funded_amount ? @order_amount : @funded_amount
    withdraw_amount     = (withdraw_amount * 100).to_i
    withdraw_amount_str = Money.new(withdraw_amount).format
    
    withdraw_funded_account(withdraw_amount)
    
    if current_user && @order.valid? &&
      ((@ssl_account.funded_account.cents + withdraw_amount) == @funded_account_init)
      save_free_order
      invoice_paid
      flash[:notice] = "Succesfully paid full amount of #{withdraw_amount_str} from funded account for invoice."
      redirect_to_invoice
    else
      flash[:error] = "Something went wrong, did not withdraw #{withdraw_amount_str} from funded account!"
      redirect_new_payment
    end
  end
  
  def save_free_order
    @order.billing_profile_id = nil
    @order.deducted_from_id = nil
    @order.state = 'paid'
    record_order_visit(@order)
    @order.save
  end
  
  def invoice_paid
    if @order.persisted?
      @invoice.update(order_id: @order.id, status: 'paid')
      @invoice.notify_invoice_paid(current_user) if Settings.invoice_notify
    end
  end
  
  def redirect_new_payment
    new_params = {ssl_slug: @ssl_slug,id: @invoice.reference_number}
    if params[:billing_profile]
      new_params[:billing_profile] = params[:billing_profile].delete_if do |k, v|
        %w{card_number security_code stripe_card_token}.include?(k)
      end
    end
    redirect_to new_payment_invoice_path(new_params)
  end
  
  def redirect_to_invoice
    redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
  end

  def find_ssl_account
    if current_user
      ref = params.dig(:order, :id).presence || params[:id]
      @ssl_account = if current_user.is_system_admins?
                       Invoice.find_by(reference_number: ref)&.billable
                     else
                       current_user.ssl_account
                     end
    end
  end

  def find_invoice
    if current_user
      ref = params[:order].nil? ? params[:id] : params[:order][:id]
      @invoice = if current_user.is_system_admins?
        Invoice.find_by(reference_number: ref)
      else
        current_user.ssl_account.invoices.find_by(reference_number: ref)
      end
      switch_to_invoice_team
    end
  end
  
  def switch_to_invoice_team
    unless current_user.is_system_admins?
      ref = params[:order].nil? ? params[:id] : params[:order][:id]
      approved_teams = current_user.get_all_approved_accounts
      # Couldn't find invoice in users default team.
      if @invoice.nil?
        @invoice = approved_teams.map(&:invoices).flatten.find { |i| i.reference_number == ref }
      end
      # Switch user to invoices team
      if @invoice && @invoice.billable != @ssl_account &&
        approved_teams.map(&:id).include?(@invoice.billable.id)
          
          current_user.set_default_ssl_account(@invoice.billable.id)
          flash[:notice]      = "You have switched to team %s."
          flash[:notice_item] = "<strong>#{current_user.ssl_account.get_team_name}</strong>"
          set_ssl_slug(current_user)
      end
    end
  end
end
