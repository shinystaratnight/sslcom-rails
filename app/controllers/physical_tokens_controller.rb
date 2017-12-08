class PhysicalTokensController < ApplicationController
  before_action :set_certificate_order
  before_action :set_physical_token, only: [:show, :update, :destroy, :edit]
  before_action :require_user
  filter_access_to :all

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
      head :no_content
    else
      render json: @physical_token.errors, status: :unprocessable_entity
    end
  end

  # DELETE /physical_tokens/1
  # DELETE /physical_tokens/1.json
  def destroy
    @physical_token.destroy

    head :no_content
  end

  private

    def set_certificate_order
      @certificate_order = CertificateOrder.find_by_ref(params[:certificate_order_id])
    end

    def set_physical_token
      @physical_token = PhysicalToken.find(params[:id])
    end

    def physical_token_params
      params.require(:physical_token).permit(:certificate_order_id, :signed_certificate_id, :tracking_number, :shipping_method, :activation_pin, :manufacturer, :model_number, :serial_number)
    end
end
