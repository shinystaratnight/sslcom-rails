class ManagedCsrsController < ApplicationController
  before_action :require_user, :set_ssl_slug, except: [:new, :add_generated_csr]
  before_action :global_set_row_page, only: [:index]
  before_action :set_sign_hash_algorithms, :find_ssl_account, only: [:new]

  def index
    @csrs = (current_user.ssl_account.all_csrs).paginate(@p)
  end

  def new
    if params[:cert_ref]
      @cert_ref = params[:cert_ref]
      @for_reprocess = params[:is_reprocess]
      @certificate_order=@ssl_account.certificate_orders.find_by_ref(@cert_ref)
    elsif params[:cert_token]
      @is_server = params[:is_server]
      @cert_token = params[:cert_token]
      co_token = CertificateOrderToken.find_by_token(params[:cert_token])
      @error_cert_ref = co_token.certificate_order.ref
    end

    unless current_user.blank?
      @csr = ManagedCsr.new
      @cert_orders = current_user.ssl_account.certificate_orders.unused.map{|cert_order| [cert_order.ref, cert_order.id]}
    end
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

    if params[:is_logged_in] == 'true'
      if current_user
        if params[:csr_id]
          @csr = current_user.ssl_account.all_csrs.find_by(id: params[:csr_id])
          @csr.body = params[:csr]
          @csr.friendly_name = params[:friendly_name] && !params[:friendly_name].empty? ? params[:friendly_name] : nil

          if @csr.save
            returnObj['status'] = 'true'
            returnObj['csr_ref'] = @csr.ref
            returnObj['hash'] = @csr.public_key_sha1
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
            returnObj['csr_ref'] = @csr.ref
            returnObj['hash'] = @csr.public_key_sha1
          else
            returnObj['status'] = 'There was a problem adding this CSR to the CSR Manager.'
          end
        end
      else
        returnObj['status'] = 'no_user'
        returnObj['url'] = new_user_session_url
      end
    else
      @csr = ManagedCsr.new
      @csr.body = params[:csr]

      returnObj['status'] = 'true'
      returnObj['hash'] = @csr.public_key_sha1
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

  def remove_managed_csrs
    csr_ids = params['checkbox_csrs']
    csr_ids.each do |csr_id|
      csr = current_user.ssl_account.all_csrs.find_by(id: csr_id)
      csr.destroy unless csr.blank?
    end

    render :json => 'success'
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

  def set_sign_hash_algorithms
    @sign_alg = [
        ['RSASSA-PKCS1-v1_5', 'RSASSA-PKCS1-v1_5'],
        ['ECDSA', 'ECDSA'],
        ['RSA-PSS', 'RSA-PSS']
    ]

    @rsa_key_size = [
        ['2048', '2048'],
        ['4096', '4096']
    ]

    @ec_key_size = [
        ['256', '256'],
        ['384', '384']
    ]
  end
end