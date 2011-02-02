module ValidationsHelper
  def overall_status(validation_rulings)
    unless validation_rulings.empty?
      if validation_rulings.detect(&:new?)
        unless @cert_order.is_express_signup?
          [ValidationRuling::NEW_STATUS, ValidationRuling::ATTENTION_CLASS]
        else
          [ValidationRuling::PENDING_EXPRESS_STATUS, ValidationRuling::WAITING_CLASS]
        end
      elsif validation_rulings.detect(&:more_required?)
        [ValidationRuling::MORE_REQUIRED_STATUS, ValidationRuling::ATTENTION_CLASS]
      elsif validation_rulings.detect(&:pending?)
        [ValidationRuling::PENDING_STATUS, ValidationRuling::WAITING_CLASS]
      elsif validation_rulings.detect(&:unapproved?)
        [ValidationRuling::UNAPPROVED_STATUS, ValidationRuling::ATTENTION_CLASS]
      elsif validation_rulings.all?(&:approved?)
        [ValidationRuling::APPROVED_STATUS, ValidationRuling::APPROVED_CLASS]
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
        [certificate_order_status(cc),status_class(cc)]
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
end
