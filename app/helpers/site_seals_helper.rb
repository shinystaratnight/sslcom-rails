module SiteSealsHelper
  def site_seal_status(site_seal)
    case site_seal.workflow_state
    when "new"
      [SiteSeal::NEW_STATUS, 'attention']
    when SiteSeal::FULLY_ACTIVATED.to_s
      [SiteSeal::FULLY_ACTIVATED_STATUS, 'approved']
    when SiteSeal::CONDITIONALLY_ACTIVATED.to_s
      [SiteSeal::CONDITIONALLY_ACTIVATED_STATUS, 'pending']
    when SiteSeal::DEACTIVATED.to_s
      [SiteSeal::DEACTIVATED_STATUS, 'attention']
    when SiteSeal::CANCELED.to_s
      [SiteSeal::CANCELED_STATUS, 'attention']
    else
      ['','']
    end
  end

  def friendly_seal_type(seal_type)
    case seal_type
    when 'ev'
      'extended validation premium'
    when 'ov'
      'high assurance standard'
    when 'dv'
      'basic'
    end
  end

  def certificate_status(co, is_managing=nil)
    pending = is_managing ? "pending" : "warning"
    cc=co.certificate_content
    case cc.workflow_state
    when "issued"
      if cc.csr.signed_certificate.blank?
        ["certificate missing", "attention"]
      else
        ef, ex = [cc.csr.signed_certificate.effective_date, cc.csr.
          signed_certificate.expiration_date]
        if ex.blank? || ef.blank?
          #these were signed certs transferred over and somehow were missing these dates
          ["invalid certificate", "attention"]
        elsif ex < Time.now
          ["invalid (expired on #{ex.strftime("%b %d, %Y")})", pending]
        elsif ef > Time.now
          ["invalid (starts on #{ef.strftime("%b %d, %Y")})", pending]
        else
          ["valid (#{ef.strftime("%b %d, %Y")} - #{ex.strftime("%b %d, %Y")})",
            "approved"]
        end
      end
    when "canceled"
      ["canceled", "attention"]
    when "revoked"
      ["revoked", "attention"]
    else
      ["pending issuance", pending]
    end
  end

  def popup_code(co)
    {style: "border: none;", onclick:
        "window.open('#{site_report_site_seal_url(@ssl_slug, co.site_seal)}', 'site_report','#{co.validation_histories.blank? ?
        SiteSeal::REPORT_DIMENSIONS : SiteSeal::REPORT_ARTIFACTS_DIMENSIONS}'); return false;",
        onmouseover: "this.style.cursor='pointer'"}
  end
end
