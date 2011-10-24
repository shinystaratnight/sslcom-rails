class CertificatesController < ApplicationController
  before_filter :find_tier
  before_filter :require_user, :only=>[:buy],
    :if=>'current_subdomain==Reseller::SUBDOMAIN'

  def index
    @certificates = @tier.blank? ? Certificate.root_products :
      Certificate.tiered_products(@tier)
  end

  def single_domain
    @certificates = Certificate.find(:all)
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
    @certificates = Certificate.find(:all)
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
    @certificate = Certificate.find_by_product(params[:id]+@tier)
    @certificates = Certificate.find(:all)
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
    @certificate = Certificate.find_by_product(params[:id]+@tier)
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
    @certificates = Certificate.find(:all)
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
end
