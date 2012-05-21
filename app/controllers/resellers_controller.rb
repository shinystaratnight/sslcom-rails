class ResellersController < ApplicationController
  before_filter :require_user, :except=>[:index, :details]
  skip_before_filter :finish_reseller_signup

  def index
    flash.now[:notice] ||= params[:notice]
  end

  def new
    @reseller = current_user.ssl_account.reseller || Reseller.new
    if @reseller.nil? || @reseller.new?
      @reseller = Reseller.new if @reseller.nil?
      render :action => :new
    elsif @reseller.select_tier?
      determine_tier
      render :action => :select_tier
    elsif @reseller.enter_billing_information?
      @funded_account = current_user.ssl_account.funded_account
      @funded_account.deduct_order = "false"
      redirect_to allocate_funds_url
    elsif @reseller.complete?
      redirect_to account_url
    end
  end

  def create
    unless current_user.role_symbols.include?(Role::RESELLER.to_sym)
      current_user.roles << Role.find_by_name(Role::RESELLER)
      current_user.roles.delete Role.find_by_name(Role::CUSTOMER)
      current_user.ssl_account.add_role! "new_reseller"
      current_user.ssl_account.set_reseller_default_prefs
    end
    @reseller = current_user.ssl_account.reseller
    if !params["prev.x".intern].nil?
      go_backward
    elsif !params["cancel.x".intern].nil?
      cancel
    else
      go_forward
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
    redirect_to new_account_reseller_url
  end
  
private

  def determine_tier
    tier = @reseller.reseller_tier
    @reseller_tier = ResellerTier.new
    @reseller_tier.id = tier.nil? ? ResellerTier::DEFAULT_TIER : tier.id
  end

  def go_forward
    if @reseller.nil? || @reseller.new?
      current_user.ssl_account.create_reseller if @reseller.nil?
      #prevent the form from sumitting to update, we need to create a new
      reseller = Reseller.new(params[:reseller])
      reseller.ssl_account = current_user.ssl_account
      if reseller.valid?
        #atts was a hack because the direct merge! doesn't work
        atts = current_user.ssl_account.reseller.attributes.merge reseller.attributes
        current_user.ssl_account.reseller.attributes = atts
        current_user.ssl_account.reseller.save
        @reseller = current_user.ssl_account.reseller
        @reseller.profile_submitted!
        determine_tier
        render :action => :select_tier
      else
        @reseller = reseller
        render :action => :new
      end
    elsif @reseller.select_tier?
      if params[:reseller_tier].blank? || params[:reseller_tier][:id].blank?
        @reseller_tier = ResellerTier.new
        @reseller_tier.errors[:base] << "is not a viable tier selection"
      else
        @reseller_tier = ResellerTier.find(params[:reseller_tier][:id])
        @reseller.reseller_tier = @reseller_tier
      end
      if @reseller_tier.errors.empty? && @reseller.save
        @reseller.tier_selected!
        #TODO complete this
        if @reseller_tier.is_free?
          @reseller.finish_signup @reseller_tier
        end
        @reseller_tier.is_free? ?
          redirect_to(account_url, {:notice => Reseller::WELCOME}) :
          redirect_to(allocate_funds_url)
      else
        render :action => :select_tier
      end
    elsif @reseller.enter_billing_information?
      redirect_to (current_user.ssl_account.has_role?('new_reseller')) ?
        allocate_funds_url :
        allocate_funds_for_order_url
    elsif @reseller.complete?
    end
  end

  def go_backward
    @reseller.back! unless @reseller.nil?
    if @reseller.nil? || @reseller.new?
      #to prevent redirect to update method, we clone the object
      @reseller = @reseller.clone
      render :action => :new
    elsif @reseller.select_tier?
      @reseller_tier = @reseller.reseller_tier
      render :action => :select_tier
    elsif @reseller.enter_billing_information?
      redirect_to allocate_funds_url
    end
  end
end
