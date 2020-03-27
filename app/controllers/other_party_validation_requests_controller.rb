class OtherPartyValidationRequestsController < ApplicationController
  respond_to :json, only: :create
  respond_to :html, only: :show
  before_action :require_user, only: :show
  #filter_access_to :all

  def create
    @other_party_validation_request =
      OtherPartyValidationRequest.new(params[:other_party_validation_request])
    @other_party_validation_request.user = current_user
    @other_party_validation_request.save
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
