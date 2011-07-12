class OtherPartyValidationRequestsController < ApplicationController
  respond_to :json, only: :create
  respond_to :html, only: :show

  def create
    @other_party_validation_request =
      OtherPartyValidationRequest.create(params[:other_party_validation_request])
    respond_with @other_party_validation_request
  end

  def show
    @other_party_validation_request = OtherPartyValidationRequest.find_by_identifier(params[:id])
    if @other_party_validation_request && @other_party_validation_request.allowed(current_user.email)
      @certificate_order = @other_party_validation_request.other_party_requestable
      render 'validations/edit'
    else
      permission_denied
    end
  end
end
