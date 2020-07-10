class PhoneCallbacksController < ApplicationController
  before_action :require_user
  before_action :check_if_super_user?, only: %i[approvals]
  before_action :check_if_sys_admin?, only: %i[verifications]
  before_action :set_per_page

  def approvals
    if params[:search].present?
      @certificate_orders = CertificateOrder.includes(:messages, :registrants, :certificate_contents)
        .where(ref: params[:search])
        .joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }
        .where(registrants: { phone_number_approved: false })
        .where(messages: { subject: 'Request for approving Phone Number' } )
      if @certificate_orders.empty?
        render :approvals
      else
        @certificate_orders = @certificate_orders.paginate(page: params[:page], per_page: @per_page || 10)
      end
    else
      @certificate_orders = find_pending_approvals.paginate(page: params[:page], per_page: @per_page || 10)
    end
  end

  def verifications
    if params[:search].present?
      @certificate_orders = CertificateOrder.includes(:certificate_order_tokens, :registrants, :certificate_contents)
      .where(ref: params[:search])
      .where.not(contacts: { contactable_id: nil })
      .where.not(certificate_contents: { workflow_state: 'issued' })
      .where(certificate_order_tokens: { status: 'pending', callback_type: 'manual', callback_method: 'call' })
      if @certificate_orders.empty?
        render :verifications
      else
        @certificate_orders = @certificate_orders.paginate(page: params[:page], per_page: @per_page || 10)
      end
    else
      @certificate_orders = find_pending_verifications.paginate(page: params[:page], per_page: @per_page || 10)
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
    @per_page = params[:number_rows]
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
    @certificate_orders = CertificateOrder.includes(:messages, :registrants, :certificate_contents)
      .joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }
      .where(registrants: { phone_number_approved: false })
      .where(messages: { subject: 'Request for approving Phone Number' } )
  end

  def find_pending_verifications
    @certificate_orders = CertificateOrder.includes(:certificate_order_tokens, :registrants, :certificate_contents)
      .where.not(contacts: { contactable_id: nil })
      .where.not(certificate_contents: { workflow_state: 'issued' })
      .where(certificate_order_tokens: { status: 'pending', callback_type: 'manual', callback_method: 'call' })
  end
end
