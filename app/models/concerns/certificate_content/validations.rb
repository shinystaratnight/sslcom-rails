# frozen_string_literal: true

module Concerns
  module CertificateContent
    module Validations
      extend ActiveSupport::Concern
      include Concerns::CertificateContent

      included do
        validates_presence_of :server_software_id, :signing_request, # :agreement, # need to test :agreement out on reprocess and api submits
                              if: 'certificate_order_has_csr && !ajax_check_csr && Settings.require_server_software_w_csr_submit'
        validates_format_of :signing_request, with: SIGNING_REQUEST_REGEX,
                                              message: 'contains invalid characters.',
                                              if: :certificate_order_has_csr_and_signing_request
        validate :domains_validation, if: :validate_domains?
        validate :csr_validation, if: 'new? && csr'
      end
    end
  end
end