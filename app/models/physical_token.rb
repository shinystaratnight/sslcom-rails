class PhysicalToken < ActiveRecord::Base
  MAKE_AND_MODELS={Gemalto: %w(5100\ eToken)}
  CARRIERS=%w(FedEx UPS USPS DHL in-person)

  belongs_to :certificate_order
  belongs_to :signed_certificate

  after_initialize do
    self.activation_pin=SecureRandom.base64(8)
  end

  after_save do
    if tracking_number and new?
      ship_token!
    end
  end

  include Workflow
  workflow do
    state :new do
      event :ship_token, :transitions_to => :in_transit
      event :confirm_serial, :transitions_to => :in_possession
      event :soft_delete, :transitions_to => :soft_deleted
    end

    state :in_transit do
      event :shipping_recipient_confirmation, :transitions_to => :received
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