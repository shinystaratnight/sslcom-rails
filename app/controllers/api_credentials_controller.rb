class ApiCredentialsController < ApplicationController
  before_filter    :require_user

  def new
  end

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
    @acs = @acs.order("created_at desc").paginate(p)

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
    @ac = ApiCredential.new(params[:api_credential].except(:role_ids))
    @ac.save
    redirect_to api_credentials_path(ssl_slug: @ssl_slug)
  end

  def edit
    @ac = ApiCredential.find(params[:id])
    if current_user.is_system_admins?
      @user_accounts_roles = User.get_user_accounts_roles(@user)
    end
    @role_ids = @ac.role_ids
  end

  def update
    role_ids = params[:api_credential][:role_ids].reject(&:blank?)
    @ac = ApiCredential.find(params[:id])
    @ac.roles = role_ids.to_json
    @ac.save
    redirect_to api_credentials_path(ssl_slug: @ssl_slug)
  end

  def remove
    @ac = ApiCredential.find(params[:id])
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
end
