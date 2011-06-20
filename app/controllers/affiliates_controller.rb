class AffiliatesController < ApplicationController
  resource_controller
#  ssl_required :new, :create, :update, :edit
  belongs_to :user
  before_filter :login_required, :except => [:show, :about, :refer]
  before_filter :allowed_to_create?, :only=>[:new, :create]
  before_filter :protect_affiliate, :only => [:edit_profile, :edit,
    :update_profile, :update, :destroy, :dashboard, :link_codes]

  create.before do
    object.user_id = current_user.id
  end

  create.after do
    current_user.register_for_affiliate!
  end

  create.wants.html{redirect_to dashboard_affiliate_path(object)}

  def refer
    id = params[:id]
    cookies[:aid] = {:value=>id, :path => "/", :expires => Settings.
        cart_cookie_days.to_i.days.from_now} if Affiliate.exists?(id)
    redirect_to request.url.gsub(/\/code\/\w+\/?$/,"")
  end

  def update_profile
    @avatar = AffiliatePhoto.new(params[:avatar])
    @avatar.affiliate = @affiliate
    if @avatar.save
      @affiliate.avatar = @avatar
    end
    respond_to do |format|
      if @affiliate.update_attributes(params[:affiliate])
        format.html { redirect_to affiliate_path(@affiliate) }
      else
        format.html { render :action => "edit_profile" }
      end
    end
  end

  protected

  def allowed_to_create?
    ([:pending].include?(current_user.current_state) or !current_user.affiliates.empty?)? access_denied : true
  end

  def parent_object
    object.user
  end

  private

  def protect_affiliate
    @affiliate = Affiliate.find(params[:id])
    unless current_user.affiliates.first == @affiliate
      access_denied
    end
  end


end