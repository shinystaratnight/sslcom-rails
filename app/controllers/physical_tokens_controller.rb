class PhysicalTokensController < ApplicationController
  before_action :set_certificate_order
  before_action :set_physical_token, only: [:show, :update, :destroy, :edit, :activate]
  before_action :require_user
  filter_access_to :all
  filter_access_to  :activate, :require=>:read

  def new
    @physical_token = @certificate_order.physical_tokens.new
  end

  # POST /physical_tokens
  # POST /physical_tokens.json
  def create
    @physical_token = @certificate_order.physical_tokens.new(physical_token_params)

    if @physical_token.save
      redirect_to certificate_order_path @certificate_order
    else
      format.html { render :action => "new" }
    end
  end

  # PATCH/PUT /physical_tokens/1
  # PATCH/PUT /physical_tokens/1.json
  def update
    if @physical_token.update(physical_token_params)
      redirect_to certificate_order_path @certificate_order
    else
      format.html { render :action => "new" }
    end
  end

  # DELETE /physical_tokens/1
  # DELETE /physical_tokens/1.json
  def destroy
    @physical_token.soft_delete!

    redirect_to certificate_order_path @certificate_order
  end

  def activate
    if params[:serial]==@physical_token.serial_number
      @physical_token.confirm_serial!
      flash[:notice] = "Token #{@physical_token.name} serial number confirmed. PIN is #{@physical_token.activation_pin}"
    else
      flash[:error] = "Serial number is not valid for token '#{@physical_token.name}'"
    end
    redirect_to certificate_order_path @certificate_order
  end

  def edit

  end

  private

    def set_certificate_order
      @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
    end

    def set_physical_token
      @physical_token = PhysicalToken.active.find(params[:id])
    end

    def physical_token_params
      params.require(:physical_token).permit(:certificate_order_id, :signed_certificate_id, :tracking_number,
               :shipping_method, :activation_pin, :admin_pin, :manufacturer, :model_number, :serial_number, :name)
    end
end
