# frozen_string_literal: true

module Concerns
  module CertificateOrder
    module Association
      extend ActiveSupport::Concern
      include Concerns::CertificateOrder::Constants

      included do
        belongs_to  :ssl_account, touch: true
        belongs_to  :folder, touch: true
        has_many    :users, through: :ssl_account
        belongs_to  :assignee, class_name: 'User'
        belongs_to  :validation
        has_many    :validation_histories, through: :validation
        belongs_to  :site_seal
        belongs_to :parent, class_name: 'CertificateOrder', foreign_key: :renewal_id
        has_one :renewal, class_name: 'CertificateOrder', foreign_key: :renewal_id, dependent: :destroy # represents a child renewal
        has_many    :renewal_attempts
        has_many    :renewal_notifications
        has_many    :cdns
        has_many :certificate_contents, dependent: :destroy, after_add: proc { |p, _| p.certificate_content(true) }
        has_many :certificate_names, through: :certificate_contents
        has_one :locked_recipient, class_name: 'LockedRecipient', as: :contactable, dependent: :destroy, foreign_key: :contactable_id, inverse_of: :certificate_order
        has_many    :registrants, through: :certificate_contents
        has_many    :locked_registrants, through: :certificate_contents
        has_many    :certificate_contacts, through: :certificate_contents
        has_many    :domain_control_validations, through: :certificate_names
        has_many :csrs, through: :certificate_contents, source: 'csr'
        has_many    :csr_unique_values, through: :csrs
        has_many    :attestation_certificates, through: :certificate_contents
        has_many    :signed_certificates, through: :csrs, source: :signed_certificate do
          def expired
            where{ expiration_date < Time.zone.today }
          end
        end
        has_many :attestation_certificates, through: :certificate_contents do
          def expired
            where{ expiration_date < Time.zone.today }
          end
        end
        has_many :attestation_issuer_certificates, through: :certificate_contents
        has_many :shadow_certificates, through: :csrs, class_name: 'ShadowSignedCertificate'
        has_many :ca_certificate_requests, through: :csrs
        has_many :ca_api_requests, through: :csrs
        has_many :sslcom_ca_requests, through: :csrs
        has_many :sub_order_items, as: :sub_itemable, dependent: :destroy, inverse_of: :sub_itemable
        has_many :product_variant_items, through: :sub_order_items, dependent: :destroy
        has_many :orders, through: :line_items, unscoped: true
        has_many    :other_party_validation_requests, class_name: 'OtherPartyValidationRequest', as: :other_party_requestable, dependent: :destroy
        has_many    :ca_retrieve_certificates, as: :api_requestable, dependent: :destroy
        has_many    :ca_mdc_statuses, as: :api_requestable
        has_many    :jois, as: :contactable, class_name: 'Joi' # for SSL.com EV; rw by vetting agents, r by customer
        has_many    :app_reps, as: :contactable, class_name: 'AppRep' # for SSL.com OV and EV; rw by vetting agents, r by customer
        has_many    :physical_tokens
        has_many :url_callbacks, as: :callbackable, through: :certificate_contents
        has_many    :taggings, as: :taggable
        has_many    :tags, through: :taggings
        has_many    :notification_groups_subjects, as: :subjectable
        has_many    :notification_groups, through: :notification_groups_subjects
        has_many    :certificate_order_tokens
        has_many    :certificate_order_managed_csrs, dependent: :destroy
        has_many    :managed_csrs, through: :certificate_order_managed_csrs
        has_many    :certificate_order_domains, dependent: :destroy
        has_many :managed_domains, through: :certificate_order_domains, source: :domain
      end
    end
  end
end
