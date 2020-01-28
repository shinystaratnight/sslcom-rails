module ValidationsHelper
  def overall_status(validation_rulings)
    unless validation_rulings.empty?
      dcvs=@cert_order.csr.domain_control_validations
      last_sent=%w(http https).include?(dcvs.last.try(:dcv_method)) ? dcvs.last : dcvs.last_sent
      dcv_wait=(!@cert_order.csr.blank? && last_sent.try("satisfied?")) ? "" :
          ", waiting for response to domain control validation email"
      if validation_rulings.detect(&:new?)
        unless @cert_order.express_signup?
          [(@cert_order.certificate.is_ev? ? ValidationRuling::NEW_EV_STATUS : ValidationRuling::NEW_STATUS)+dcv_wait,
           ValidationRuling::ATTENTION_CLASS]
        else
          [ValidationRuling::PENDING_EXPRESS_STATUS+dcv_wait, ValidationRuling::WAITING_CLASS]
        end
      elsif validation_rulings.detect(&:more_required?)
        [ValidationRuling::MORE_REQUIRED_STATUS+dcv_wait, ValidationRuling::ATTENTION_CLASS]
      elsif validation_rulings.detect(&:pending?)
        [ValidationRuling::PENDING_STATUS+dcv_wait, ValidationRuling::WAITING_CLASS]
      elsif validation_rulings.detect(&:unapproved?)
        [ValidationRuling::UNAPPROVED_STATUS+dcv_wait, ValidationRuling::ATTENTION_CLASS]
      elsif validation_rulings.all?(&:approved?)
        [ValidationRuling::APPROVED_STATUS+dcv_wait, ValidationRuling::APPROVED_CLASS]
      else
        ['','']
      end
    else
      if @cert_order.migrated_from_v2?
        #we need to depend on existence of csr and.or signed cert
        if @cert_order.certificate_content.csr.blank?
          ["please submit certificate signing request (csr)", ValidationRuling::WAITING_CLASS]
        elsif @cert_order.signed_certificate.blank?
          ["processing certificate", ValidationRuling::WAITING_CLASS]
        else
          ['','']
        end
      else
        cc = @cert_order.certificate_content
        [certificate_order_status(cc,@cert_order),status_class(cc)]
      end
    end
  end

  def validation_status(validation_ruling)
    if validation_ruling.new?
      [ValidationRuling::WAITING_FOR_DOCS, ValidationRuling::ATTENTION_CLASS]
    elsif validation_ruling.more_required?
      [ValidationRuling::INSUFFICIENT, ValidationRuling::ATTENTION_CLASS]
    elsif validation_ruling.pending?
      [ValidationRuling::REVIEWING, ValidationRuling::WAITING_CLASS]
    elsif validation_ruling.approved?
      [ValidationRuling::APPROVED, ValidationRuling::APPROVED_CLASS]
    elsif validation_ruling.unapproved?
      [ValidationRuling::UNAPPROVED, ValidationRuling::ATTENTION_CLASS]
    else
      ['','']
    end
  end

  def satisfied(last_sent)
    last_sent.satisfied? ? "dcv_satisfied" : "dcv_not_satisfied"
  end

  def last_sent(co)
    return if co.csr.blank?
    dcvs=co.csr.domain_control_validations
    (%w(http https).include?(dcvs.last.try(:dcv_method))) ? dcvs.last : dcvs.last_sent
  end
end
