class ManagedUsersController < ApplicationController

  filter_access_to :create

  def new
    @user=User.new
  end

  def create
    @user = current_user.ssl_account.users.new
    @user.login = params[:user][:email]
    if request.subdomain == Reseller::SUBDOMAIN
      @user.ssl_account.add_role! "new_reseller"
      @user.ssl_account.set_reseller_default_prefs
      @user.roles << Role.find_by_name(Role::RESELLER)
    else
      @user.roles << Role.find_by_name(Role::CUSTOMER)
    end
    if @user.signup!(params)
      @user.deliver_signup_invitation!(current_user, root_url)
      notice = "An invitation has been sent to #{@user.email} with account activation instructions"
      flash[:notice] = notice
      redirect_to users_path
    else
      render action: :new
    end
  end

  def edit
    @user = User.find(params[:id])
    @role_ids = @user.roles.pluck(:id)
  end

  def update
    @user = @user=User.find(params[:id])
    @user.assign_roles(params)
    ActiveRecord::Base.transaction do
      if @user.save && @user.remove_roles(params)
        notice = "#{@user.first_name} #{@user.last_name}'s roles have been updated"
        flash[:notice] = notice
        redirect_to users_path
      else
        redirect_to action: :edit
      end
    end
  end

end
