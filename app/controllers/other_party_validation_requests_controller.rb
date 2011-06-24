class OtherPartyValidationRequestsController < ApplicationController
  respond_to :json

  def create
    @other_party_validation_request =
      OtherPartyValidationRequest.create(params[:other_party_validation_request])
    respond_with @other_party_validation_request
  end
end
