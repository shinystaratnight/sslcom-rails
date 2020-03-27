class PasswordResetsController < ApplicationController
  before_action :require_no_user
  before_action :find_dup_login, :find_dup_email, only: [:create]
  before_action :load_user_using_perishable_token, :only => [:edit, :update]

  def index
    redirect_to new_password_reset_path
  end

  def edit
    render
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    if @user.save
      flash[:notice] = "Password successfully updated"
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def new
    render
  end

  def create
    if verify_recaptcha(response: params['g-recaptcha-response'])
      unless params[:login].blank?
        @user = User.find_by_login(params[:login])
        if @user
          @user.deliver_password_reset_instructions!
          flash[:notice] =
              "Instructions to reset your password have been emailed to you. Please check your email."
          redirect_to login_url
        else
          flash[:notice] = "No user was found with that login"
          render :action => :new
        end
      else
        @user = User.find_by_email(params[:email])
        if @user
          @user.deliver_username_reminder!
          flash[:notice] =
              "Your username has been emailed to you. Please check your email."
          redirect_to login_url
        else
          flash[:notice] = "No user was found with that email"
          render :action => :new
        end
      end
    else
      flash[:notice] = "Are you human?"
      render :action => :new
    end
  end

  private

  def load_user_using_perishable_token
    @user = User.find_by_perishable_token(params[:id])
    unless @user
      flash[:notice] = <<-EOS
        We're sorry, but we could not locate your account.
        If you are having issues try copying and pasting the URL
        from your email into your browser or restarting the
        reset password process.
      EOS
      redirect_to login_url
    end
  end
end
