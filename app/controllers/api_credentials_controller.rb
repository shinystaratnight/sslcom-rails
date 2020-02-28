class ApiCredentialsController < ApplicationController
  before_filter    :require_user

  def index
    p = {:page => params[:page],per_page: 10}
    set_apis

    if params[:search]
      search = params[:search].strip.split(" ")
      role = nil
      search.delete_if {|s|s =~ /role\:(.+)/; role ||= $1; $1}
      search = search.join(" ")
      @acs = @acs.with_role(role) if role
      @acs = @acs.search(search) unless search.blank?
    end
    @acs = @acs.order("created_at desc").paginate(p).decorate

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @acs }
    end
  end

  def new
    @ac=ApiCredential.new
  end

  def create
    role_ids = params[:api_credential][:role_ids].reject(&:blank?)
    params[:api_credential][:roles] = role_ids.to_json
    params[:api_credential][:ssl_account_id] = current_user.ssl_account.id
    params[:api_credential][:secret_key] = params[:api_credential][:acc_secret_key]
    @ac = ApiCredential.new(params[:api_credential].except(:role_ids, :acc_id, :acc_secret_key))
    @ac.save
    redirect_to api_credentials_path(ssl_slug: @ssl_slug)
  end

  def edit
    @ac = find_api_credential(params[:id])
    if current_user.is_system_admins?
      @user_accounts_roles = User.get_user_accounts_roles(@user)
    end
    @role_ids = @ac.role_ids
  end

  def update
    role_ids = params[:api_credential][:role_ids].reject(&:blank?)
    @ac = find_api_credential(params[:id])
    @ac.account_key = params[:api_credential][:account_key]
    @ac.secret_key = params[:api_credential][:acc_secret_key]
    @ac.roles = role_ids.to_json
    @ac.save
    redirect_to api_credentials_path(ssl_slug: @ssl_slug)
  end

  def reset_credential
    @ac = find_api_credential(params[:acc_id])
    new_ac = ApiCredential.new
    @ac.secret_key = new_ac.secret_key
    @ac.save
    respond_to do |format|
      format.js {render json: new_ac.to_json}
    end  
  end

  def remove
    @ac = find_api_credential(params[:id])
    @ac.destroy
    redirect_to api_credentials_path(ssl_slug: @ssl_slug)
  end

  private
  
  def set_apis
    if current_user.is_system_admins?
      @acs = @ssl_account.try(:api_credentials) || ApiCredential.unscoped
    else
      @acs = current_user.manageable_acs
    end
  end

  def find_api_credential(id)
    if current_user.is_system_admins?
      ApiCredential.find(id)
    else
      current_user.ssl_account.api_credentials.find(id)
    end
  end
end
