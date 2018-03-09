class InvoicesController < ApplicationController
  include OrdersHelper
  
  before_filter :find_invoice, except: :index
  before_filter :find_ssl_account, except: :index
  before_filter :set_ssl_slug, except: :index
  
  filter_access_to :all
  filter_access_to :show, :update_invoice
  
  def index
    @invoices = invoices_base_query
    @invoices = @invoices.index_filter(params) if params[:commit]
    @invoices = @invoices.paginate(page: params[:page], per_page: 25)
  end
  
  def download
    if @invoice
      render pdf: "ssl.com_monthly_invoice_#{@invoice.reference_number}"
    else
      flash[:error] = "This invoice doesn't exist."
      redirect_to :back
    end
  end
  
  def show
    @order = @invoice.payment unless @invoice.payment.nil?
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
    @monthly_invoice = true
  end
  
  def make_payment
    @monthly_invoice = true
    ucc_or_invoice_params
    
    @order = Order.new(
      billing_profile_id: params[:funding_source],
      amount:             @target_amount,
      cents:              (@target_amount * 100).to_i,
      description:        Order::INVOICE_PAYMENT,
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
  
  def make_payment_other
    pmt_type = MonthlyInvoice::PAYMENT_METHODS_TEXT[params[:ptm_type].to_sym]
    if @invoice && !@invoice.paid?
      @order = Order.new(
        amount:      @invoice.get_amount,
        cents:       @invoice.get_cents,
        description: Order::INVOICE_PAYMENT,
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
    
  private
  
  def invoices_base_query
    base = if current_user && current_user.is_system_admins?
      MonthlyInvoice
    else
      current_user.ssl_account.monthly_invoices
    end
    base.joins(:orders).uniq.sort_with(params)
  end
  
  def payment_hybrid
    if current_user && order_reqs_valid? && !@too_many_declines && purchase_successful?
      save_billing_profile unless (params[:funding_source])
      @order.billing_profile = @profile
      withdraw_funded_account((@funded_amount * 100).to_i) if @funded_amount > 0
      invoice_paid
      record_order_visit(@order)
      
      flash[:notice] = "Succesfully paid for invoice #{@invoice.reference_number}."
      redirect_to_invoice
    else
      if @too_many_declines
        flash[:error] = 'Too many failed attempts, please wait 1 minute to try again!'
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
    @invoice.update(order_id: @order.id, status: 'paid') if @order.persisted?
  end
  
  def redirect_new_payment
    redirect_to new_payment_invoice_path(@ssl_slug, @invoice.reference_number)
  end
  
  def redirect_to_invoice
    redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
  end
  
  def find_ssl_account
    if current_user
      ref = params[:order].nil? ? params[:id] : params[:order][:id]
      @ssl_account = if current_user.is_system_admins?
        MonthlyInvoice.find_by(reference_number: ref).billable
      else
        current_user.ssl_account
      end
    end
  end
  
  def find_invoice
    if current_user
      ref = params[:order].nil? ? params[:id] : params[:order][:id]
      @invoice = if current_user.is_system_admins?
        MonthlyInvoice.find_by(reference_number: ref)
      else
        current_user.ssl_account.monthly_invoices.find_by(reference_number: ref)
      end
    end
  end
  
  def set_ssl_slug(target_user=nil)
    if current_user && @ssl_account
      @ssl_slug ||= (@ssl_account.ssl_slug || @ssl_account.acct_number)
    end
  end
end
