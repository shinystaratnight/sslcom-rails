# frozen_string_literal: true

module Concerns
  module CertificateName
    module Scope
      extend ActiveSupport::Concern

      included do
        scope :find_by_domains, ->(domains){ includes(:domain_control_validations).where{ name >> domains } }
        scope :validated, ->{ joins(:domain_control_validations).where{ domain_control_validations.workflow_state == 'satisfied' } }
        scope :last_domain_control_validation, ->{ joins(:domain_control_validations).limit(1) }
        scope :expired_validation, lambda {
          joins(:domain_control_validations)
            .where('domain_control_validations.id = (SELECT MAX(domain_control_validations.id) FROM domain_control_validations WHERE domain_control_validations.certificate_name_id = certificate_names.id)')
            .where{ (domain_control_validations.responded_at < DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago.to_date) }
        }
        scope :unvalidated, lambda {
          satisfied = <<~SQL
          SELECT COUNT(domain_control_validations.id) FROM domain_control_validations
          WHERE certificate_name_id = certificate_names.id AND workflow_state='satisfied'
          SQL
          total = <<~SQL
          SELECT COUNT(domain_control_validations.id) FROM domain_control_validations
          WHERE certificate_name_id = certificate_names.id
          SQL
          where "(#{total}) >= 0 AND (#{satisfied}) = 0"
        }
        scope :sslcom, ->{ joins{ certificate_content }.where.not certificate_contents: { ca_id: nil } }
        scope :global, -> { where{ (certificate_content_id == nil) & (ssl_account_id == nil) & (acme_account_id == nil) } }
        scope :search_domains, lambda { |term|
          term ||= ''
          term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
          filters = { email: nil, name: nil, expired_validation: nil }

          filters.each do |fn, _fv|
            term.delete_if do |str|
              str =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?")
              filters[fn] ||= $1
              $1
            end
          end

          term = term.empty? ? nil : term.join(' ')

          return nil if [term, *filters.values].compact.empty?

          result = all
          unless term.blank?
            result = result.where do
              (email =~ "%#{term}%") | (name =~ "%#{term}%")
            end
          end

          %w[expired_validation].each do |field|
            query = filters[field.to_sym]
            result = result.expired_validation if query
          end

          result.uniq.order(created_at: :desc)
        }
      end
    end
  end
end
