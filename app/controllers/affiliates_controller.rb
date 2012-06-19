class AffiliatesController < ApplicationController
  before_filter :require_user, :except=>[:index, :details]
  before_filter :find_affiliate, only: [:show, :sales, :links]

  def new
    @affiliate =  Affiliate.new
  end

  def create
    @affiliate = Affiliate.new(params[:affiliate])
    @affiliate.ssl_account = current_user.ssl_account
    if @affiliate.save
      flash[:notice]="Congrats! You can start earning commissions immediately as an ssl.com affiliate."
      redirect_to affiliate_url(@affiliate)
    else
      render action: "new"
    end
  end

  def update
    @reseller = current_user.ssl_account.reseller
    unless params["prev.x".intern].nil?
      go_backward
    else
      go_forward
    end
  end

  def show
    p = {:page => params[:page]}
    @stats = @affiliate.sales_stats
  end

  def sales
    p = {:page => params[:page]}
    @stats = @affiliate.sales_stats
  end

  def refer
    id = params[:id]
    cookies[:aid] = {:value=>id, :path => "/", :expires => Settings.
        cart_cookie_days.to_i.days.from_now} if Affiliate.exists?(id)
    redirect_to request.url.gsub(/\/code\/\w+\/?$/,"")
  end


#  belongs_to :user
#  before_filter :login_required, :except => [:show, :about, :refer]
#  before_filter :allowed_to_create?, :only=>[:new, :create]
#  before_filter :protect_affiliate, :only => [:edit_profile, :edit,
#    :update_profile, :update, :destroy, :dashboard, :link_codes]
#
#  create.before do
#    object.user_id = current_user.id
#  end
#
#  create.after do
#    current_user.register_for_affiliate!
#  end
#
#  create.wants.html{redirect_to dashboard_affiliate_path(object)}
#
#  def refer
#    id = params[:id]
#    cookies[:aid] = {:value=>id, :path => "/", :expires => Settings.
#        cart_cookie_days.to_i.days.from_now} if Affiliate.exists?(id)
#    redirect_to request.url.gsub(/\/code\/\w+\/?$/,"")
#  end
#
#  def update_profile
#    @avatar = AffiliatePhoto.new(params[:avatar])
#    @avatar.affiliate = @affiliate
#    if @avatar.save
#      @affiliate.avatar = @avatar
#    end
#    respond_to do |format|
#      if @affiliate.update_attributes(params[:affiliate])
#        format.html { redirect_to affiliate_path(@affiliate) }
#      else
#        format.html { render :action => "edit_profile" }
#      end
#    end
#  end
#
#  protected
#
#  def allowed_to_create?
#    ([:pending].include?(current_user.current_state) or !current_user.affiliates.empty?)? access_denied : true
#  end
#
#  def parent_object
#    object.user
#  end
#
  private

  def find_affiliate
    @affiliate = Affiliate.find(params[:id])
  end
#
#  def protect_affiliate
#    @affiliate = Affiliate.find(params[:id])
#    unless current_user.affiliates.first == @affiliate
#      access_denied
#    end
#  end
#
#
end