require 'airbrake/delayed_job'

class DomainJob < Struct.new(:cc, :acc, :dcv_failure_action, :domains, :dcv_candidate_addresses)
  def perform
    cc.dcv_domains({ domains: (domains || [cc.csr.common_name]), emails: dcv_candidate_addresses, dcv_failure_action: dcv_failure_action })
    cc.pend_validation!(ca_certificate_id: acc[:ca_certificate_id], send_to_ca: acc[:send_to_ca] || true) unless cc.pending_validation?
  end
end
