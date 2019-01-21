class ManagedCsrsController < ApplicationController
  before_filter :require_user
  before_filter :set_row_page, only: [:index]

  def index
    @csrs = (current_user.ssl_account.all_csrs).paginate(@p)
  end

  def new
    @csr = ManagedCsr.new
    @cert_orders = current_user.ssl_account.certificate_orders.unused.map{|cert_order| [cert_order.ref, cert_order.id]}
  end

  def create
    # redirect_to new_managed_csr_path(@ssl_slug) and return unless current_user
    # @csr = ManagedCsr.new(params[:managed_csr])
    # @csr.ssl_account_id = current_user.ssl_account.id
    # respond_to do |format|
    #   if !current_user.ssl_account.all_csrs.find_by_public_key_sha1(@csr.public_key_sha1).blank?
    #     flash[:notice] = "Csr already exists on team #{current_user.ssl_account.ssl_slug}."
    #     format.html {redirect_to managed_csrs_path(@ssl_slug)}
    #   elsif @csr.save
    #     flash[:notice] = "Csr was successfully added."
    #     format.html {redirect_to managed_csrs_path(@ssl_slug)}
    #   else
    #     flash[:error] = "There was a problem adding this CSR to the CSR Manager"
    #     format.html {redirect_to new_managed_csr_path(@ssl_slug)}
    #   end
    # end

    redirect_to new_managed_csr_path(@ssl_slug) and return unless current_user
    @csr = ManagedCsr.new
    @csr.friendly_name = params[:friendly_name] && !params[:friendly_name].empty? ? params[:friendly_name] : nil
    @csr.body = params[:csr]
    @csr.ssl_account_id = current_user.ssl_account.id

    respond_to do |format|
      if !current_user.ssl_account.all_csrs.find_by_public_key_sha1(@csr.public_key_sha1).blank?
        flash[:notice] = "Csr already exists on team #{current_user.ssl_account.ssl_slug}."
        format.html {redirect_to managed_csrs_path(@ssl_slug)}
      elsif @csr.save
        # certificate_order = @ssl_account.certificate_orders.find(params[:cert_order])
        # certificate_order.certificate_content.csr = @csr

        flash[:notice] = "Csr was successfully added."
        format.html {redirect_to managed_csrs_path(@ssl_slug)}
      else
        flash[:error] = "There was a problem adding this CSR to the CSR Manager"
        format.html {redirect_to new_managed_csr_path(@ssl_slug)}
      end
    end
  end

  def add_generated_csr
    returnObj = {}

    if params[:csr_id]
      @csr = current_user.ssl_account.all_csrs.find_by(id: params[:csr_id])
      @csr.body = params[:csr]
      @csr.friendly_name = params[:friendly_name] && !params[:friendly_name].empty? ? params[:friendly_name] : nil

      if @csr.save
        returnObj['status'] = 'true'
      else
        returnObj['status'] = 'There was a problem adding this CSR to the CSR Manager.'
      end
    else
      @csr = ManagedCsr.new
      @csr.friendly_name = params[:friendly_name] && !params[:friendly_name].empty? ? params[:friendly_name] : nil
      @csr.body = params[:csr]
      @csr.ssl_account_id = current_user.ssl_account.id

      if !current_user.ssl_account.all_csrs.find_by_public_key_sha1(@csr.public_key_sha1).blank?
        returnObj['status'] = 'CSR already exists on team' + current_user.ssl_account.ssl_slug + '.'
      elsif @csr.save
        returnObj['status'] = 'true'
      else
        returnObj['status'] = 'There was a problem adding this CSR to the CSR Manager.'
      end
    end

    render :json => returnObj
  end

  def edit
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
  end

  def update
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
    # @csr.friendly_name = params[:csr][:friendly_name]
    # @csr.body = params[:csr][:body]
    @csr.body = params[:csr]
    @csr.friendly_name = params[:friendly_name] && !params[:friendly_name].empty? ? params[:friendly_name] : nil
    @csr.save

    redirect_to managed_csrs_path(@ssl_slug)
  end

  def destroy
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
    if @csr
      @csr.destroy
      flash[:notice] = "Csr was successfully deleted."
    else
      flash[:error] = "Csr not found."
    end
    respond_to do |format|
      format.html { redirect_to managed_csrs_path(@ssl_slug) }
    end
  end

  def show_csr_detail
    if current_user
      @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])

      render :partial=>'detailed_info', :locals=>{:csr=>@csr}
    else
      render :json => 'no-user'
    end
  end

  private
  def set_row_page
    @per_page = params[:per_page] ? params[:per_page] : 10
    Csr.per_page = @per_page if Csr.per_page != @per_page

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end
end