class SiteSeal < ActiveRecord::Base
  #using_access_control
  has_many  :certificate_orders
  attr_protected :workflow_state

  EV_SEAL = 'ev'
  OV_SEAL = 'ov'
  DV_SEAL = 'dv'

  FREE_SEAL_IMAGE = 'free_ssl_trust_logo.gif'
  SEAL_IMAGE = 'ssl_trust_logo.gif'

  REPORT_CACHE_KEY = "ssl_com_report_"

  REPORT_DIMENSIONS = 'height=500, width=400, top=100, left=100'

  FULLY_ACTIVATED = :fully_activated
  CONDITIONALLY_ACTIVATED = :conditionally_activated
  DEACTIVATED = :deactivated
  CANCELED = :canceled
  
  ACTIVATE = "activate"
  
  NEW_STATUS = 
    "site seal has not been activated yet"
  FULLY_ACTIVATED_STATUS =
    "site seal has been fully activated with all features"
  CONDITIONALLY_ACTIVATED_STATUS =
    "site seal has been partially activated, pending final approval"
  DEACTIVATED_STATUS =
    "site seal has been temporarily deactivated"
  CANCELED_STATUS =
    "site seal has been disabled pending investigation"

  CLICK_TO_EXPAND = 'click to for more details'

  before_create {|ss|
    ss.ref=SecureRandom.hex(4)+'-'+Time.now.to_i.to_s(16)
  }

  preference  :seal_image, :string
  preference  :artifacts_status, :string, :default=>ACTIVATE

  include Workflow
  workflow do
    state :new do
      event :fully_activate, :transitions_to => FULLY_ACTIVATED
      event :conditionally_activate, :transitions_to => CONDITIONALLY_ACTIVATED
      event :deactivate, :transitions_to => DEACTIVATED
      event :report_abuse, :transitions_to => CANCELED

      on_exit do
        update_seal_type
      end
    end

    state FULLY_ACTIVATED do
      event :conditionally_activate, :transitions_to => CONDITIONALLY_ACTIVATED
      event :deactivate, :transitions_to => DEACTIVATED
      event :report_abuse, :transitions_to => CANCELED
    end

    state CONDITIONALLY_ACTIVATED do
      event :fully_activate, :transitions_to => FULLY_ACTIVATED
      event :deactivate, :transitions_to => DEACTIVATED
      event :report_abuse, :transitions_to => CANCELED
    end

    state DEACTIVATED do
      event :fully_activate, :transitions_to => FULLY_ACTIVATED
      event :conditionally_activate, :transitions_to => CONDITIONALLY_ACTIVATED
      event :report_abuse, :transitions_to => CANCELED
    end

    state CANCELED do
      event :fully_activate, :transitions_to => FULLY_ACTIVATED
      event :conditionally_activate, :transitions_to => CONDITIONALLY_ACTIVATED
      event :deactivate, :transitions_to => DEACTIVATED
    end
  end

  def update_seal_type
    if certificate_order.migrated_from_v2?
      if certificate_order.preferred_v2_product_description.downcase =~/trial/
        self.update_attributes :seal_type=>DV_SEAL, :preferred_seal_image=>
          FREE_SEAL_IMAGE
      else
        self.update_attributes :seal_type=>OV_SEAL, :preferred_seal_image=>
          SEAL_IMAGE
      end
    else
      self.update_attributes SiteSeal.generate_options(certificate_order.
          certificate.product)
    end
    Rails.cache.delete REPORT_CACHE_KEY+self.id.to_s
  end

  def to_param
    ref
  end

  def self.generate_options(product)
    case product
    when /ev/
      {:seal_type=>EV_SEAL, :preferred_seal_image=>SEAL_IMAGE}
    when /high_assurance/, /ucc/, /wildcard/, /premiumssl/, /basicssl/
      {:seal_type=>OV_SEAL, :preferred_seal_image=>SEAL_IMAGE}
    when /free/
      {:seal_type=>DV_SEAL, :preferred_seal_image=>FREE_SEAL_IMAGE}
    end
  end

  def certificate_order
    certificate_orders.last
  end

  def has_artifacts?
    !certificate_order.validation_histories.
      select(&:can_publish_to_site_seal?).empty? &&
      preferred_artifacts_status == ACTIVATE
  end
  
  def status
    
  end

  def is_disabled?
    canceled? || deactivated? || new?
  end

  def latest_certificate_order

    #having issues with UCC so simplify
    certificate_order

    #cn=certificate_order.common_name
    #acct = certificate_order.ssl_account_id
    #CertificateOrder.joins{certificate_contents.csr}.where{
    #    (ssl_account_id=="#{acct}") &
    #    (certificate_contents.csr.common_name == "#{cn}")}.
    #    order("certificate_orders.created_at desc").first
  end
end
