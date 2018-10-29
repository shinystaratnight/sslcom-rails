class ManagedCsrsController < ApplicationController
  before_filter :require_user
  before_filter :set_row_page, only: [:index]

  def index
    @csrs = (current_user.ssl_account.all_csrs).paginate(@p)
  end

  def new
    @csr=ManagedCsr.new
  end

  def create
    redirect_to new_managed_csr_path(@ssl_slug) and return unless current_user
    @csr = ManagedCsr.new(params[:managed_csr])
    @csr.ssl_account_id = current_user.ssl_account.id
    respond_to do |format|
      if @csr.save
        flash[:notice] = "Csr was successfully added."
        format.html {redirect_to managed_csrs_path(@ssl_slug)}
      else
        flash[:error] = "There was a problem adding this CSR to the CSR Manager"
        format.html {redirect_to new_managed_csr_path(@ssl_slug)}
      end
    end
  end

  def edit
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
  end

  def update
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
    @csr.friendly_name = params[:csr][:friendly_name]
    @csr.body = params[:csr][:body]
    @csr.save
    redirect_to managed_csrs_path(@ssl_slug)
  end

  def destroy
    @csr = current_user.ssl_account.all_csrs.find_by(id: params[:id])
    @csr.destroy
    respond_to do |format|
      flash[:notice] = "Csr was successfully deleted."
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