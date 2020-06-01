class AffiliatesController < ApplicationController
  before_action :require_user, :except=>[:index, :details, :refer]
  before_action :find_affiliate, only: [:show, :sales, :links]
  filter_access_to :update, attribute_check: true
  filter_access_to :show, :sales, :links, attribute_check: true, require: :read

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
  end

  def sales
  end

  def refer
    id = params[:id]
    if Affiliate.exists?(id)
      set_cookie(ShoppingCart::AID,id)
      set_cookie(:ref,request.url)
    end
    if id=="21"
      redirect_to "https://affiliates.ssl.com/program.php?id=101&url=#{request.url.gsub(/\/code\/\w+\/?\z/,"")}"
    elsif id=="35"
      redirect_to "https://affiliates.ssl.com/program.php?id=102&url=#{request.url.gsub(/\/code\/\w+\/?\z/,"")}"
    else
      redirect_to request.url.gsub(/\/code\/\w+\/?\z/,"")
    end
  end

  private

  def find_affiliate
    @affiliate = Affiliate.find(params[:id])
  end
end
