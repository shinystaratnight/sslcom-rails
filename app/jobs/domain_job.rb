# frozen_string_literal: true

class DomainJob < Struct.new(:cc, :acc, :dcv_failure_action, :domains, :dcv_candidate_addresses)
  def perform
    cc.dcv_domains({ domains: (domains || [cc.csr.common_name]), emails: dcv_candidate_addresses, dcv_failure_action: dcv_failure_action })
    cc.pend_validation!(ca_certificate_id: acc[:ca_certificate_id], send_to_ca: acc[:send_to_ca] || true) unless cc.pending_validation?
  end

  def reschedule_at(_attempts, _time)
    next_rate_limit_window if is_acme
  end

  def max_attempts
    if is_acme
      10
    else
      Delayed::Worker.max_attempts
    end
  end

  def next_rate_limit_window
    5.seconds.from_now
  end

  def dcv_method
    cc&.domain_control_validations&.last_method&.dcv_method
  end

  def is_acme
    @is_acme ||= dcv_method =~ /^acme/
  end
end
