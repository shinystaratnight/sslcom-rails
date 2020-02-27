# frozen_string_literal: true

module Concerns
  module CertificateContent
    module Workflow
      extend ActiveSupport::Concern

      included do
        workflow do
          state :new do
            event :submit_csr, transitions_to: :csr_submitted
            event :provide_info, transitions_to: :info_provided
            event :cancel, transitions_to: :canceled
            event :issue, transitions_to: :issued
            event :reset, transitions_to: :new
            event :validate, transitions_to: :validated
            event :pend_validation, transitions_to: :pending_validation
          end

          state :csr_submitted do
            event :issue, transitions_to: :issued
            event :provide_info, transitions_to: :info_provided
            event :reprocess, transitions_to: :reprocess_requested
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
            event :pend_issuance, transitions_to: :pending_issuance
          end

          state :info_provided do
            event :validate, transitions_to: :validated
            event :submit_csr, transitions_to: :csr_submitted
            event :issue, transitions_to: :issued
            event :provide_contacts, transitions_to: :contacts_provided
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
            event :pend_issuance, transitions_to: :pending_issuance
            event :pend_validation, transitions_to: :pending_validation do |options = {}|
              pre_validation(options)
            end
          end

          state :contacts_provided do
            event :validate, transitions_to: :validated
            event :provide_contacts, transitions_to: :contacts_provided
            event :submit_csr, transitions_to: :csr_submitted
            event :issue, transitions_to: :issued
            event :pend_issuance, transitions_to: :pending_issuance
            event :pend_validation, transitions_to: :pending_validation do |options = {}|
              pre_validation(options)
            end
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
          end

          state :pending_validation do
            event :issue, transitions_to: :issued
            event :validate, transitions_to: :validated do
              self.preferred_reprocessing = false if preferred_reprocessing?
            end
            event :pend_issuance, transitions_to: :pending_issuance
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
          end

          state :validated do
            event :pend_validation, transitions_to: :pending_validation
            event :pend_issuance, transitions_to: :pending_issuance
            event :issue, transitions_to: :issued
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
            event :revoke, transitions_to: :revoked
          end

          state :pending_issuance do
            event :pend_validation, transitions_to: :pending_validation
            event :pend_issuance, transitions_to: :pending_issuance
            event :validate, transitions_to: :validated
            event :issue, transitions_to: :issued
            event :cancel, transitions_to: :canceled
            event :reset, transitions_to: :new
          end

          state :issued do
            event :reprocess, transitions_to: :csr_submitted
            event :pend_issuance, transitions_to: :pending_issuance
            event :validate, transitions_to: :validated
            event :cancel, transitions_to: :canceled
            event :revoke, transitions_to: :revoked
            event :issue, transitions_to: :issued
            event :reset, transitions_to: :new
          end

          state :canceled

          state :revoked do
            event :revoke, transitions_to: :revoked
          end
        end
      end
    end
  end
end
