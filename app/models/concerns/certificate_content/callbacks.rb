# frozen_string_literal: true

module Concerns
  module CertificateContent
    module Callbacks
      extend ActiveSupport::Concern

      included do
        after_create :certificate_names_from_domains, unless: :certificate_names_created?
        after_save   :certificate_names_from_domains, unless: :certificate_names_created?
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

      def certificate_names_created?
        reload
        return false if domains.blank? && !certificate_name_from_csr?

        new_domains     = parse_unique_domains(domains)
        current_domains = parse_unique_domains(certificate_names.pluck(:name))
        common          = current_domains & new_domains
        common.length == new_domains.length && (current_domains.length == new_domains.length)
      end

      def certificate_name_from_csr?
        certificate_names.count == 1 &&
          csr.common_name &&
          certificate_names.first.name == csr.common_name &&
          certificate_names.first.is_common_name
      end
    end
  end
end
