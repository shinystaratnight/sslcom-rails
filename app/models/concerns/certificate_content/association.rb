# frozen_string_literal: true

module Concerns
  module CertificateContent
    module Association
      extend ActiveSupport::Concern

      included do
        belongs_to  :certificate_order, -> { unscope(where: %i[workflow_state is_expired]) }, touch: true
        has_one     :ssl_account, through: :certificate_order
        has_many    :users, through: :certificate_order
        belongs_to  :server_software
        has_one     :csr, dependent: :destroy
        has_many    :csrs, dependent: :destroy
        has_many    :signed_certificates, through: :csr, source: 'signed_certificate'
        has_one     :registrant, as: :contactable, dependent: :destroy
        has_one     :locked_registrant, as: :contactable
        has_many    :certificate_contacts, as: :contactable
        has_many    :certificate_names, dependent: :destroy do # used for dcv of each domain in a UCC or multi domain ssl
          def validated
            joins{ domain_control_validations }.where{ domain_control_validations.workflow_state == 'satisfied' }.uniq
          end
        end
        has_many    :domain_control_validations, through: :certificate_names
        has_many    :url_callbacks, dependent: :destroy, as: :callbackable
        has_many    :taggings, dependent: :destroy, as: :taggable
        has_many    :tags, through: :taggings
        belongs_to  :ca
        has_many    :sslcom_ca_requests, as: :api_requestable
        has_many    :attestation_certificates
        has_many    :attestation_issuer_certificates

        accepts_nested_attributes_for :certificate_contacts, allow_destroy: true
        accepts_nested_attributes_for :registrant, allow_destroy: false
        accepts_nested_attributes_for :csr, allow_destroy: false
      end
    end
  end
end
