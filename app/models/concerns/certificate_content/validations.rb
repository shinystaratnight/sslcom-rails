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

      def domains_validation
        unless all_domains.blank?
          all_domains.each do |domain|
            domain_validation(domain)
          end
        end
        self.rekey_certificate = false unless domains.blank?
      end

      # This validates each domain entry in the CN and SAN fields
      def domain_validation_regex(is_wildcard, domain)
        invalid_chars = "[^\\s\\n\\w\\.\\x00\\-#{'\\*' if is_wildcard}]"
        domain.index(Regexp.new(invalid_chars)).nil? &&
          domain.index(/\.\.+/).nil? && domain.index(/\A\./).nil? &&
          domain.index(/[^\w]\z/).nil? && domain.index(/\A[^\w\*]/).nil? &&
          is_wildcard ? (domain.index(/(\w)\*/).nil? &&
            domain.index(/(\*)[^\.]/).nil?) : true
      end

      def certificate_order_has_csr
        ['true', true].any?{ |t| t == certificate_order.try(:has_csr) }
      end

      def certificate_order_has_csr_and_signing_request
        certificate_order_has_csr && !signing_request.blank?
      end

      def validate_domains?
        (new? && (domains.blank? || errors[:domain].any?)) || !rekey_certificate.blank?
      end

      def csr_validation
        allow_wildcard_ucc = certificate_order.certificate.allow_wildcard_ucc?
        is_wildcard = certificate_order.certificate.is_wildcard?
        is_ucc = certificate_order.certificate.is_ucc?
        is_server = certificate_order.certificate.is_server?
        if csr.common_name.blank?
          errors.add(:signing_request, 'is missing the common name (CN) field or is invalid and cannot be parsed')
        elsif !csr.verify_signature
          errors.add(:signing_request, 'has an invalid signature')
        else
          if is_server
            asterisk_found = (csr.common_name =~ /\A\*\./) == 0
            if is_wildcard && !asterisk_found
              errors.add(:signing_request, 'is wildcard certificate order, so it must begin with *.')
            elsif ((!(is_ucc && allow_wildcard_ucc) && !is_wildcard)) && asterisk_found
              errors.add(:signing_request, 'cannot begin with *. since the order does not allow wildcards')
            elsif !DomainNameValidator.valid?(csr.common_name)
              errors.add(:signing_request, 'common name field is invalid')
            end
          end
          if csr.sig_alg =~ /WithRSAEncryption/i && (csr.strength.blank? || !MIN_KEY_SIZE.include?(csr.strength))
            errors.add(:signing_request, "must be any of the following #{MIN_KEY_SIZE.join(', ')} key sizes.
              Please submit a new certificate signing request with the proper key size.")
          end
        end
      end
    end
  end
end
