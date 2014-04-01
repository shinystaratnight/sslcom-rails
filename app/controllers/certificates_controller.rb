class CertificatesController < ApplicationController
  before_filter :find_tier
  before_filter :require_user, :only=>[:buy],
    :if=>'current_subdomain==Reseller::SUBDOMAIN'
  before_filter :find_certificate, only: [:show, :buy]

  def index
    @certificates = Rails.cache.fetch(@tier.blank? ? "tier_nil" : "tier_#{@tier}", expires_in: 30.days) do
        @tier.blank? ? Certificate.root_products : Certificate.tiered_products(@tier)
    end
  end

  def single_domain
    @certificates = Certificate.public
    unless @tier.blank?
      @certificates = @certificates.find_all{|c|
        c.product=~Regexp.new(@tier) && c.is_single?}
    else
      @certificates = @certificates.reject{|c|
        c.product=~/\dtr/ || c.is_multi?}
    end
    render :action=>'single_or_multi'
  end

  def wildcard_or_ucc
    @certificates = Certificate.public
    unless @tier.blank?
      @certificates = @certificates.find_all{|c|
        c.product=~Regexp.new(@tier) && c.is_multi?}
    else
      @certificates = @certificates.reject{|c|
        c.product=~/\dtr/ || c.is_single?}
    end
    render :action=>'single_or_multi'
  end

  # GET /certificate/wildcard
  # GET /certificate/wildcard.xml
  def show
    @certificates = Certificate.public
    unless @tier.blank?
      @certificates = @certificates.find_all{|c|
        c.product=~Regexp.new(@tier)}
    else
      @certificates = @certificates.reject{|c|
        c.product=~/\dtr/}
    end
    respond_to do |format|
      unless @certificate.blank?
        format.html { render :action => "show_"+@certificate.product_root}
        format.xml  { render :xml => @certificate}
      else
        format.html {not_found}
      end
    end
  end

  # GET /certificate/buy/wildcard
  # GET /certificate/buy/wildcard.xml
  def buy
    prep_purchase
  end

  def find_tier
    @tier =''
    if current_user and current_user.ssl_account.has_role?('reseller')
      @tier = current_user.ssl_account.reseller_tier_label + 'tr'
    elsif cookies[:r_tier]
      @tier = cookies[:r_tier] + 'tr'
    end
  end

  def get_certificates_list
    @certificates = Certificate.public
    unless @tier.blank?
      @certificates = @certificates.find_all{|c|
        c.product=~Regexp.new(@tier) && c.is_single?}
    else
      @certificates = @certificates.reject{|c|
        c.product=~/\dtr/ || c.is_multi?}
    end
  end

  private

  def prep_purchase
    unless @certificate.blank?
      @certificate_order = CertificateOrder.new(:duration=>
          (params[:id]=='free') ? 1 : 2)
      @certificate_order.ssl_account=
        current_user.ssl_account unless current_user.blank?
      @certificate_order.has_csr=false #this is the single flag that hides/shows the csr prompt
      @certificate_content = CertificateContent.new()
      respond_to do |format|
          format.html # buy.html.haml
          format.xml  { render :xml => @certificate}
      end
    else
      not_found
    end
  end

  def find_certificate
    prod = params[:id]=='mssl' ? 'high_assurance' : params[:id]
    @certificate = Certificate.for_sale.find_by_product(prod+@tier)
  end
end
