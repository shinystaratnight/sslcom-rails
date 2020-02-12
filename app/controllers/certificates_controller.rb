# frozen_string_literal: true

class CertificatesController < ApplicationController
  before_filter :find_tier
  before_filter :require_user, only: %i[buy buy_renewal], if: 'request.subdomain==Reseller::SUBDOMAIN'
  before_filter :require_user, only: %i[admin_index new edit create update manage_product_variants]
  before_filter :find_certificate, only: %i[show buy pricing buy_renewal]
  before_filter :find_certificate_by_id, only: %i[edit update manage_product_variants]
  filter_access_to :edit, :update, :manage_product_variants, attribute_check: true
  filter_access_to :buy_renewal, :new, :admin_index, :create
  layout false, only: [:pricing]

  def index
    @certificates = if Rails.env.development?
                      @tier.blank? ? Certificate.root_products : Certificate.tiered_products(@tier)
                    else
                      Rails.cache.fetch(@tier.blank? ? 'tier_nil' : "tier_#{@tier}", expires_in: 30.days) do
                        @tier.blank? ? Certificate.root_products : Certificate.tiered_products(@tier)
                      end
                    end
  end

  def single_domain
    @certificates = Certificate.available
    @certificates = if @tier.blank?
                      @certificates.reject{ |c| c.product =~ /\dtr/ || c.is_multi? }
                    else
                      @certificates.find_all{ |c| c.product =~ Regexp.new(@tier) && c.is_single? }
                    end
    render action: 'single_or_multi'
  end

  def wildcard_or_ucc
    @certificates = Certificate.available
    @certificates = if @tier.blank?
                      @certificates.reject{ |c| c.product =~ /\dtr/ || c.is_single? }
                    else
                      @certificates.find_all{ |c| c.product =~ Regexp.new(@tier) && c.is_multi? }
                    end
    render action: 'single_or_multi'
  end

  # GET /certificate/wildcard
  # GET /certificate/wildcard.xml
  def show
    @certificates = Certificate.available
    @certificates = if @tier.blank?
                      @certificates.reject{ |c| c.product =~ /\dtr/ }
                    else
                      @certificates.find_all{ |c| c.product =~ Regexp.new(@tier) }
                    end
    respond_to do |format|
      if @certificate.blank?
        format.html { not_found }
      else
        format.html { render action: 'show_' + @certificate.product_root }
        format.xml { render xml: @certificate }
      end
    end
  end

  # GET /certificate/buy/wildcard
  # GET /certificate/buy/wildcard.xml
  def buy
    prep_purchase
    respond_to do |format|
      if @certificate.blank?
        format.html { not_found }
      else
        format.html { render 'certificate_orders/submit_csr' }
        format.xml  { render xml: @certificate }
      end
    end
  end

  def buy_renewal
    buy
  end

  def get_certificates_list
    @certificates = Certificate.available
    @certificates = if @tier.blank?
                      @certificates.reject{ |c| c.product =~ /\dtr/ || c.is_multi? }
                    else
                      @certificates.find_all{ |c| c.product =~ Regexp.new(@tier) && c.is_single? }
                    end
  end

  def pricing
    prep_purchase
    @values = @certificate.pricing(@certificate_order, @certificate_content)
    respond_to do |format|
      if @certificate.blank?
        format.html { not_found }
      else
        format.html { render action: 'pricing' }
        format.js { render action: 'pricing' }
        format.json { render action: 'pricing' }
        format.xml { render xml: @certificate }
      end
    end
  end

  def new
    @certificate = Certificate.new
  end

  def edit
  end

  def update
    parse_params
    if @certificate.update(@new_params)
      update_cas_certificates
      flash[:notice] = "Certificate #{@certificate.serial} was successfully updated."
      log_system_audit(:update)
      mpv_redirect_to_cert
    else
      render :edit, error: "Failed to update certificate due to errors: #{@certificate.errors.full_messages.join(', ')}."
    end
  end

  def create
    parse_params
    @certificate = Certificate.new(@new_params)
    if @certificate.save
      update_cas_certificates
      flash[:notice] = "Certificate #{@certificate.serial} was successfully created."
      log_system_audit(:create)
      mpv_redirect_to_cert
    else
      render :new, error: "Failed to create certificate due to errors: #{@certificate.errors.full_messages.join(', ')}."
    end
  end

  def manage_product_variants
    if @certificate
      @pv_group = @certificate.product_variant_groups.find(params[:pvg]) if params[:pvg]
      @pv_item = ProductVariantItem.find(params[:pvi]) if params[:pvi]
      @pvi_params = params.dup.keep_if { |k, _| (ProductVariantItem.attribute_names - ['id']).include?(k) }
      @pvg_params = params.dup.keep_if { |k, _| (ProductVariantGroup.attribute_names - ['id']).include?(k) }

      case params[:manage_type]
      when 'delete_group' then mpv_delete_group
      when 'create_group' then mpv_create_group
      when 'create_item'  then mpv_create_item
      when 'delete_item'  then mpv_delete_item
      when 'update_item' then mpv_update_item
      when 'manage_items' then mpv_manage_items
      else
        mpv_redirect_to_cert
      end
    end
  end

  def admin_index
    @certificates = Certificate.all.sort_with(params)
    @certificates = @certificates.index_filter(params) if params[:commit]
    @certificates = @certificates.paginate(page: params[:page], per_page: 25)
  end

  private

  def mpv_delete_group
    if @pv_group.destroy
      flash[:notice] = "Group #{@pv_group.id} was successfully deleted."
    else
      flash[:error] = 'Something went wrong while deleting group, please try again.'
    end
    mpv_redirect_to_cert
  end

  def mpv_create_group
    new_group = ProductVariantGroup.new(
      @pvg_params.merge(variantable_id: @certificate.id, variantable_type: 'Certificate')
    )
    if new_group.save
      flash[:notice] = 'Group was successfully created.'
    else
      flash[:error] = "Failed to create group due to errors: #{new_group.errors.full_messages.join(', ')}!"
    end
    mpv_redirect_to_cert
  end

  def mpv_create_item
    new_item = ProductVariantItem.new(
      @pvi_params.merge(product_variant_group_id: @pv_group.id)
    )
    if new_item.save
      flash[:notice] = "Item #{new_item.serial} was successfully created."
    else
      flash[:error] = "Failed to create item due to errors: #{new_item.errors.full_messages.join(', ')}!"
    end
    mpv_redirect_to_group
  end

  def mpv_delete_item
    if @pv_item&.destroy
      flash[:notice] = "Item #{@pv_item.serial} was successfully deleted."
    else
      flash[:error] = 'Something went wrong, please try again.'
    end
    mpv_redirect_to_group
  end

  def mpv_update_item
    if @pv_item&.update(@pvi_params)
      flash[:notice] = "Item #{@pv_item.serial} was successfully updated."
    else
      error = if @pv_item
                "Failed to update item #{@pv_item.serial} due to errors: #{@pv_item.errors.full_messages.join(', ')}!"
              else
                'Something went wrong, please try again.'
              end
      flash[:error] = error
    end
    mpv_redirect_to_group
  end

  def mpv_manage_items
    render :manage_product_variants
  end

  def mpv_redirect_to_group
    redirect_to manage_product_variants_certificate_path(
      @certificate.id, pvg: @pv_group, manage_type: 'manage_items'
    )
  end

  def mpv_redirect_to_cert
    redirect_to edit_certificate_path(@certificate.id)
  end

  def prep_purchase
    unless @certificate.blank?
      @certificate_order = if params[:rekeying]
                             CertificateOrder.unscoped.find_by_ref(params[:rekeying])
                           else
                             CertificateOrder.new(duration: params[:id] == 'free' ? 1 : 2)
                           end
      @certificate_order.ssl_account = current_user.ssl_account unless current_user.blank?
      @certificate_order.has_csr = false # this is the single flag that hides/shows the csr prompt
      domains = if instance_variable_get("@#{CertificateOrder::RENEWING}")
                  @certificate_order.renewal_id = instance_variable_get("@#{CertificateOrder::RENEWING}").id
                  instance_variable_get("@#{CertificateOrder::RENEWING}").certificate_content.all_domains
                else
                  @certificate_order.certificate_content ? @certificate_order.certificate_content.all_domains : []
                end
      @certificate_content = CertificateContent.new(domains: domains)
    end
  end

  def find_certificate_by_id
    cur_id = params[:certificate] ? params[:certificate][:id] : params[:id]
    @certificate = Certificate.includes(:product_variant_items).find cur_id
  end

  def parse_params
    cert = params[:certificate]
    @new_params = cert.merge(display_order: JSON.parse(cert[:display_order])).merge(description: JSON.parse(cert[:description])).to_h
  end

  def update_cas_certificates
    cas = params[:ca_certificates]
    if cas&.any?
      @certificate.cas_certificates.where.not(ca_id: cas).destroy_all
      exist_cas = @certificate.cas_certificates.where(ca_id: cas).map(&:ca)
      @certificate.cas << (Ca.where(id: cas) - exist_cas)
    else
      @certificate.cas_certificates.destroy_all
    end
  end

  def log_system_audit(type)
    action = type == :create ? 'created' : 'updated'
    SystemAudit.create(
      owner: current_user,
      target: @certificate,
      action: "User #{current_user.email} has #{action} certificate on #{DateTime.now.strftime('%b %d, %Y %R %Z')}",
      notes: "Certificate #{@certificate.serial} #{action.capitalize}"
    )
  end
end
