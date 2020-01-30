class RegisteredAgent < ApplicationRecord
  belongs_to  :ssl_account
  belongs_to  :requester, :class_name => 'User'
  belongs_to  :approver, :class_name => 'User'
  has_many :managed_certificates, dependent: :destroy

  attr_accessor :api_status, :reason

  scope :search_with_terms, lambda { |term|
    term ||= ""
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { mac_address: nil, friendly_name: nil, ref: nil, subject: nil, sans: nil,
                effective_date: nil, expiration_date: nil }

    filters.each {|fn, fv|
      term.delete_if { |s| s =~ Regexp.new(fn.to_s+"\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1 }
    }
    term = term.empty? ? nil : term.join(" ")

    return nil if [term, *(filters.values)].compact.empty?

    result = self.all
    unless term.blank?
      result = case term
                 when /sm-\w/i
                   result.where {
                     ref =~ "%#{term}%"
                   }
                 else
                   result.where {
                     (ip_address =~ "%#{term}%") |
                         (mac_address =~ "%#{term}%") |
                         (agent =~ "%#{term}%") |
                         (friendly_name =~ "%#{term}%") |
                         (workflow_status =~ "%#{term}%") |
                         (managed_certificates.common_name =~ "%#{term}%") |
                         (managed_certificates.subject_alternative_names =~ "%#{term}%")}
               end
    end

    %w(mac_address).each do |field|
      query = filters[field.to_sym]
      result = result.where(mac_address: query.split(',')) if query
    end

    %w(friendly_name).each do |field|
      query = filters[field.to_sym]
      result = result.where{ friendly_name =~ "%#{query}%" } if query
    end

    %w(ref).each do |field|
      query = filters[field.to_sym]
      result = result.where(ref: query.split(',')) if query
    end

    %w(subject).each do |field|
      query = filters[field.to_sym]
      result = result.joins(:managed_certificates).where{ managed_certificates.common_name =~ "%#{query}%" } if query
    end

    %w(sans).each do |field|
      query = filters[field.to_sym]
      result = result.joins(:managed_certificates)
                   .where{ managed_certificates.subject_alternative_names =~ "%#{query}%" } if query
    end

    %w(effective_date expiration_date).each do |field|
      query = filters[field.to_sym]
      if query
        query = query.split("-")
        start = Date.strptime query[0], "%m/%d/%Y"
        finish = query[1] ? Date.strptime(query[1], "%m/%d/%Y") : start + 1.day

        if field == "effective_date"
          result = result.joins(:managed_certificates).where{ (managed_certificates.effective_date >> (start..finish)) }
        elsif field == "expiration_date"
          result = result.joins(:managed_certificates).where{ (managed_certificates.expiration_date >> (start..finish)) }
        end
      end
    end

    result.uniq
  }

  before_create do |ra|
    ra.ref = 'sm-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
  end
end