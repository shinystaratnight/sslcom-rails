class PhoneCallbacksController < ApplicationController
  before_action :require_user
  before_action :check_if_super_user?, only: [:approvals]
  before_action :check_if_sys_admin?, only: [:verifications]
  before_action :set_per_page
  before_action :set_filter_option

  def approvals
    if params[:search].present? || params[:filter].present?
      @certificate_orders = find_pending_approvals
      if @certificate_orders.empty?
        render :approvals
      else
        @certificate_orders = @certificate_orders.paginate(page: params[:page], per_page: @per_page)
      end
    else
      @certificate_orders = find_pending_approvals.paginate(page: params[:page], per_page: @per_page)
    end
  end

  def verifications
    if params[:search].present? || params[:filter].present?
      @certificate_orders = find_pending_verifications
      if @certificate_orders.empty?
        render :verifications
      else
        @certificate_orders = @certificate_orders.paginate(page: params[:page], per_page: @per_page)
      end
    else
      @certificate_orders = find_pending_verifications.paginate(page: params[:page], per_page: @per_page)
    end
  end

  def create
    certificate_order = CertificateOrder.find_by(ref: phone_callback_log_params[:cert_order_ref])
    phone_callback_log = PhoneCallBackLog.new(phone_callback_log_params)
    if phone_callback_log.save
      certificate_order.phone_call_back_logs << phone_callback_log
      certificate_order.certificate_order_tokens.first.update(status: 'done')
      flash[:notice] = 'Phone verification successfully validated.'
      redirect_to verifications_phone_callbacks_path
    else
      render :verifications
    end
  end

  private

  def set_per_page
    preferred_row_count = current_user.try('preferred_cert_order_row_count')
    @per_page = params[:number_rows] || preferred_row_count
    CertificateOrder.per_page = @per_page if CertificateOrder.per_page != @per_page
    current_user&.update_attribute('preferred_cert_order_row_count', @per_page) if @per_page != preferred_row_count
  end

  def set_filter_option
    if (params[:filter].present? && params[:filter] == 'Filter By')
      @filter = 'Filter By'
    else
      @filter = params[:filter]
    end
  end

  def phone_callback_log_params
    params.require(:phone_callback_log).permit(:validated_by, :cert_order_ref, :phone_number).merge(validated_at: DateTime.now)
  end

  def check_if_super_user?
    redirect_to certificate_orders_path unless current_user.is_super_user?
  end

  def check_if_sys_admin?
    redirect_to certificate_orders_path unless current_user.is_admin?
  end

  def find_pending_approvals
    cos = CertificateOrder.includes(:messages, :registrants, :certificate_contents)
      .joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }
      .where(registrants: { phone_number_approved: false })
      .where(messages: { subject: 'Request for approving Phone Number' } )
    search_or_filter(cos)
  end

  def find_pending_verifications
    cos = CertificateOrder.includes(:certificate_order_tokens, :registrants, :certificate_contents)
      .where.not(contacts: { contactable_id: nil })
      .where.not(certificate_contents: { workflow_state: 'issued' })
      .where(certificate_order_tokens: { status: 'pending', callback_type: 'manual', callback_method: 'call' })
    search_or_filter(cos)
  end

  def search_or_filter(cert_orders)
    if params[:search].present?
      cert_orders = cert_orders.where(ref: params[:search])
    elsif params[:filter].present? && params[:filter] != 'Filter By'
      cert_orders = cert_orders.where("certificates.product = ?", "#{params[:filter]}")
    end
    cert_orders
  end
end
