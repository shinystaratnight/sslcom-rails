class CertificatesController < ApplicationController
  before_filter :find_tier
  before_filter :require_user, :only=>[:buy, :buy_renewal],
    :if=>'current_subdomain==Reseller::SUBDOMAIN'
  before_filter :find_certificate, only: [:show, :buy, :pricing, :buy_renewal]
  layout false, only: [:pricing]

  def index
    @certificates =
      if Rails.env.development?
        @tier.blank? ? Certificate.root_products : Certificate.tiered_products(@tier)
      else
        Rails.cache.fetch(@tier.blank? ? "tier_nil" : "tier_#{@tier}", expires_in: 30.days) do
            @tier.blank? ? Certificate.root_products : Certificate.tiered_products(@tier)
        end
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
    respond_to do |format|
      unless @certificate.blank?
        format.html { render action: (@certificate.is_ucc? ? :buy : :buy)}
        format.xml  { render :xml => @certificate}
      else
        format.html {not_found}
      end
    end
  end

  def buy_renewal
    buy
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

  def pricing
    prep_purchase
    respond_to do |format|
      unless @certificate.blank?
        format.html { render :action => "pricing"}
        format.js { render :action => "pricing"}
        format.xml  { render :xml => @certificate}
      else
        format.html {not_found}
      end
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
      domains = params[:renewing] ?
          CertificateOrder.unscoped.find_by_ref(params[:renewing]).certificate_content.all_domains : []
      @certificate_content = CertificateContent.new(domains: domains)
    end
  end

  def find_certificate
    prod = params[:id]=='mssl' ? 'high_assurance' : params[:id]
    @certificate = Certificate.for_sale.find_by_product(prod+@tier)
  end
end
