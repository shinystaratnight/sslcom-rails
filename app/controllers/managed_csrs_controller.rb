
class ManagedCsrsController < ApplicationController
  before_filter :require_user
  before_filter :set_row_page, only: [:index]

  def index
    # @csrs = (current_user.ssl_account.csrs + current_user.ssl_account.managed_csrs).paginate(@p)
    all_csrs = (current_user.ssl_account.all_csrs).sort_by{|csr| csr.created_at}.uniq{|csr| csr.common_name}
    @csrs = all_csrs.paginate(@p)
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
        format.html {redirect_to managed_csrs_path(@ssl_slug)}
      else
        format.html {redirect_to new_managed_csr_path(@ssl_slug)}
      end
    end
  end

  def edit
    @csr = current_user.ssl_account.csrs.find_by(id: params[:id])
    @csr = current_user.ssl_account.managed_csrs.find_by(id: params[:id]) if @csr.nil?
  end

  def update
    @csr = current_user.ssl_account.csrs.find_by(id: params[:id])
    @csr = current_user.ssl_account.managed_csrs.find_by(id: params[:id]) if @csr.nil?
    @csr.friendly_name = params[:csr][:friendly_name]
    @csr.body = params[:csr][:body]
    @csr.save
    redirect_to managed_csrs_path(@ssl_slug)
  end

  def destroy
    @csr = current_user.ssl_account.csrs.find_by(id: params[:id])
    @csr = current_user.ssl_account.managed_csrs.find_by(id: params[:id]) if @csr.nil?
    @csr.destroy
    respond_to do |format|
      flash[:notice] = "Csr was successfully deleted."
      format.html { redirect_to managed_csrs_path(@ssl_slug) }
    end
  end

  def show_csr_detail
    if current_user
      @csr = current_user.ssl_account.csrs.find_by(id: params[:id])
      @csr = current_user.ssl_account.managed_csrs.find_by(id: params[:id]) if @csr.nil?

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