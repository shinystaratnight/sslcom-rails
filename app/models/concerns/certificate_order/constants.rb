module Concerns
  module CertificateOrder
    module Constants
      extend ActiveSupport::Concern

      FULL = 'full'
      EXPRESS = 'express'
      PREPAID_FULL = 'prepaid_full'
      PREPAID_EXPRESS = 'prepaid_express'
      VERIFICATION_STEP = 'Perform Validation'
      CLIENT_SMIME_VALIDATE = 'client_smime_validate'
      CLIENT_SMIME_VALIDATED = 'client_smime_validated'
      CLIENT_SMIME_VALIDATED_SHORT = 'client_smime_validated_short'

      FULL_SIGNUP_PROCESS = { label: FULL, pages: %W(Submit\ CSR Payment Registrant Contacts #{VERIFICATION_STEP} Complete) }
      EXPRESS_SIGNUP_PROCESS = { label: EXPRESS, pages: FULL_SIGNUP_PROCESS[:pages] - %w(Contacts) }
      PREPAID_FULL_SIGNUP_PROCESS = { label: PREPAID_FULL, pages: FULL_SIGNUP_PROCESS[:pages] - %w(Payment) }
      NO_CSR_SIGNUP_PROCESS = { label: PREPAID_FULL, pages: PREPAID_FULL_SIGNUP_PROCESS[:pages] - %w(Submit\ CSR) }
      PREPAID_EXPRESS_SIGNUP_PROCESS = { label: PREPAID_EXPRESS, pages: EXPRESS_SIGNUP_PROCESS[:pages] - %w(Payment) }
      REPROCES_SIGNUP_W_PAYMENT = { label: FULL, pages: FULL_SIGNUP_PROCESS[:pages] }
      REPROCES_SIGNUP_W_INVOICE = { label: PREPAID_EXPRESS, pages: FULL_SIGNUP_PROCESS[:pages] - %w(Payment) }
      CLIENT_SMIME_FULL = {
        label: CLIENT_SMIME_VALIDATE,
        pages: ['Registrant', 'Recipient', 'Upload Documents', 'Complete']
      }
      CLIENT_SMIME_IV_VALIDATE = {
        label: CLIENT_SMIME_VALIDATE,
        pages: ['Recipient', 'Upload Documents', 'Complete']
      }
      CLIENT_SMIME_IV_VALIDATED = {
        label: CLIENT_SMIME_VALIDATE,
        pages: %w[Recipient Complete]
      }
      CLIENT_SMIME_NO_DOCS = {
        label: CLIENT_SMIME_VALIDATED,
        pages: %w[Registrant Recipient Complete]
      }
      CLIENT_SMIME_NO_IV_OV = {
        label: CLIENT_SMIME_VALIDATED_SHORT,
        pages: %w[Recipient Complete]
      }

      CSR_SUBMITTED = :csr_submitted
      INFO_PROVIDED = :info_provided
      REPROCESS_REQUESTED = :reprocess_requested
      CONTACTS_PROVIDED = :contacts_provided

      CA_CERTIFICATES = { SSLcomSHA2: 'SSLcomSHA2' }

      STATUS = { CSR_SUBMITTED => 'info required',
                 INFO_PROVIDED => 'contacts required',
                 REPROCESS_REQUESTED => 'csr required',
                 CONTACTS_PROVIDED => 'validation required' }

      RENEWING = 'renewing'
      REPROCESSING = 'reprocessing'
      RECERTS = [RENEWING, REPROCESSING]
      RENEWAL_DATE_CUTOFF = 45.days.ago
      RENEWAL_DATE_RANGE = 45.days.from_now
      ID_AND_TIMESTAMP = %w[id created_at updated_at]
      COMODO_SSL_MAX_DURATION = 730
      SSL_MAX_DURATION = 820
      EV_SSL_MAX_DURATION = 730
      CS_MAX_DURATION = 1095
      CLIENT_MAX_DURATION = 1095
      SMIME_MAX_DURATION = 1095
      TS_MAX_DURATION = 4106

      # included do

      # end
    end
  end
end
