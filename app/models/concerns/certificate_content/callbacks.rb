# frozen_string_literal: true

module Concerns
  module CertificateContent
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_create :certificate_names_from_domains_async, unless: :certificate_names_created?
        after_save   :certificate_names_from_domains_async, unless: :certificate_names_created?
        after_save   :transfer_existing_contacts
        before_destroy :preserve_certificate_contacts

        after_initialize do
          if new_record?
            self.ajax_check_csr ||= false
            self.signing_request ||= ''
          end
        end

        before_create do |cc|
          ref_number = cc.to_ref
          cc.ref = ref_number
          cc.label = ref_number
        end
      end
    end
  end
end
