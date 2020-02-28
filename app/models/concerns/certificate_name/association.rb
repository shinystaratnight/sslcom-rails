# frozen_string_literal: true

module Concerns
  module CertificateName
    module Association
      extend ActiveSupport::Concern

      included do
        belongs_to :certificate_content, foreign_key: 'certificate_content_id'
        has_one :ssl_account, through: :certificate_content
        has_one :csr, through: :certificate_content
        has_one :certificate_order, through: :certificate_content
        has_many    :signed_certificates, through: :certificate_content
        has_many    :caa_checks, as: :checkable
        has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
        has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
        has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
        has_many    :validated_domain_control_validations, -> { where(workflow_state: 'satisfied') }, class_name: 'DomainControlValidation'
        has_many    :last_sent_domain_control_validations, -> { where{ email_address !~ 'null' } }, class_name: 'DomainControlValidation'
        has_one :domain_control_validation, -> { order 'created_at' }, class_name: 'DomainControlValidation', unscoped: true
        has_many :domain_control_validations, dependent: :destroy do
          def last_sent
            where{ email_address !~ 'null' }.last
          end

          def last_emailed
            where{ (email_address !~ 'null') & (dcv_method >> [nil, 'email']) }.last
          end

          def last_method
            where{ dcv_method >> %w[http https email cname acme_http acme_dns_txt] }.last
          end

          def validated
            where{ workflow_state == 'satisfied' }.last
          end
        end
        has_many    :notification_groups_subjects, as: :subjectable
        has_many    :notification_groups, through: :notification_groups_subjects
      end
    end
  end
end
