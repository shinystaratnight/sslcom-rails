# frozen_string_literal: true

class DcvSentNotifyJob < Struct.new(:cc_id, :host)
  def perform
    notify_dv_sent unless last_sent.blank?
  end

  def cc
    @cc ||= CertificateContent.find cc_id
  end

  def co
    cc&.certificate_order
  end

  def notify_dv_sent
    co.valid_recipients_list.each do |c|
      OrderNotifier.dcv_sent(c, co, last_sent, host).deliver_now if host
    end
  end

  def last_sent
    if co&.certificate&.is_ucc?
      cc.certificate_names.map{ |cn| cn.last_sent_domain_control_validations.last }.flatten.compact
    else
      cc.csr.domain_control_validations.last_sent
    end
  end
end
