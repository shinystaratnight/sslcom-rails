# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  certificate_content_id :integer
#  email                  :string(255)
#  name                   :string(255)
#  is_common_name         :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  acme_account_id        :string(255)
#  ssl_account_id         :integer
#  caa_passed             :boolean          default(FALSE)
#


class Domain < CertificateName
  include Pagable

  belongs_to :ssl_account, touch: true
  has_many :certificate_order_domains, dependent: :destroy

  scope :expired_validation, -> {
    joins(:domain_control_validations)
      .where('domain_control_validations.id = (SELECT MAX(domain_control_validations.id) FROM domain_control_validations WHERE domain_control_validations.certificate_name_id = certificate_names.id)')
      .where{(domain_control_validations.responded_at < DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago.to_date)}
  }

  scope :search_domains, lambda {|term|
    term ||= ""
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { email: nil, name: nil, expired_validation: nil }

    filters.each {|fn, fv|
      term.delete_if {|str| str =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1}
    }

    term = term.empty? ? nil : term.join(' ')

    return nil if [term, *(filters.values)].compact.empty?

    result = self.all
    unless term.blank?
      result = result.where{
        (email =~ "%#{term}%") |
        (name =~ "%#{term}%")
      }
    end

    %w(expired_validation).each do |field|
      query = filters[field.to_sym]
      result = result.expired_validation if query
    end

    result.uniq.order(created_at: :desc)
  }
end
