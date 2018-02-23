class InvoicesController < ApplicationController
  include OrdersHelper
  
  before_filter    :find_invoice, except: :index
  before_filter    :find_ssl_account, only: [:new_payment, :make_payment]
  filter_access_to :all
  filter_access_to :show, :update_invoice
  
  def index
    @invoices = if current_user && current_user.is_system_admins?
      MonthlyInvoice.joins(:orders).all.order(updated_at: :asc).uniq
    else
      current_user.ssl_account.monthly_invoices.joins(:orders).order(updated_at: :asc).uniq
    end
    @invoices = @invoices.paginate(page: params[:page], per_page: 15)
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
  
  private
  
  def payment_hybrid
    if current_user && order_reqs_valid? && !@too_many_declines && purchase_successful?
      save_billing_profile unless (params[:funding_source])
      @order.billing_profile = @profile
      withdraw_funded_account((@funded_amount * 100).to_i) if @funded_amount > 0
      invoice_paid
      record_order_visit(@order)
      
      flash[:notice] = "Succesfully paid for invoice #{@invoice.reference_number}."
      redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
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
      redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
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
  
end
