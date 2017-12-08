class PhysicalToken < ActiveRecord::Base
  MAKE_AND_MODELS={Gemalto: %w(5100\ eToken)}
  CARRIERS=%w(FedEx UPS USPS)

  belongs_to :certificate_order
  belongs_to :signed_certificate

  include Workflow
  workflow do
    state :new do
      event :send, :transitions_to => :in_transit
      event :confirm_serial, :transitions_to => :in_possession
      event :soft_delete, :transitions_to => :soft_deleted
    end

    state :in_transit do
      event :confirm_serial, :transitions_to => :in_possession
      event :soft_delete, :transitions_to => :soft_deleted
    end

    state :received
    state :in_possession
    state :soft_deleted
  end

  def make_and_model
    [manufacturer,model_number].join(" ")
  end

  scope :active, ->{where{(workflow_state << ['soft_deleted'])}}
end