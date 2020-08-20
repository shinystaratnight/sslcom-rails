class PhysicalToken < ApplicationRecord
  include Workflow

  MAKE_AND_MODELS = { Gemalto: %w(5100\ eToken), Yubico: %w(Yubikey\ FIPS\ 140-2) }
  CARRIERS = ['Not Yet Shipped', 'FedEx', 'UPS', 'USPS', 'DHL', 'in-person'].freeze

  belongs_to :certificate_order
  belongs_to :signed_certificate

  after_save do
    # if tracking_number and new?
    #   ship_token!
    # end

    if tracking_number
      if new?
        shipping_method == 'Not Yet Shipped' ? in_stay! : ship_token!
      elsif not_yet_shipped? && shipping_method != 'Not Yet Shipped'
        ship_token!
      elsif in_transit? && shipping_method == 'Not Yet Shipped'
        in_stay!
      end
    end
  end

  workflow do
    state :new do
      event :in_stay, transitions_to: :not_yet_shipped
      event :ship_token, transitions_to: :in_transit
      event :confirm_serial, transitions_to: :in_possession
      event :soft_delete, transitions_to: :soft_deleted
    end

    state :not_yet_shipped do
      event :ship_token, transitions_to: :in_transit
      event :confirm_serial, transitions_to: :in_possession
      event :soft_delete, transitions_to: :soft_deleted
    end

    state :in_transit do
      event :in_stay, transitions_to: :not_yet_shipped
      event :shipping_recipient_confirmation, transitions_to: :received
      event :confirm_serial, transitions_to: :in_possession
      event :soft_delete, transitions_to: :soft_deleted
    end

    state :received
    state :in_possession
    state :soft_deleted
  end

  def make_and_model
    [manufacturer, model_number].join(' ')
  end

  scope :active, ->{where{(workflow_state << ['soft_deleted'])}}
end
