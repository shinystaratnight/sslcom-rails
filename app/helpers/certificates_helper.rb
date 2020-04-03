module CertificatesHelper
  def certificate_crumbs
    crumb = link_to "ssl certificates", certificates_path
    crumb << " :: "
    if @certificate.is_ucc? || @certificate.is_wildcard?
      crumb << link_to("wildcard or ucc", wildcard_or_ucc_certificates_url)
    else
      crumb << link_to("single domain", single_domain_certificates_url)
    end
    crumb << " :: #{@certificate.title}"
  end

  def new_certificate_params
    if @certificate_order.is_unused_credit?
      [@certificate_order, {:url=>:update_csr_certificate_order}]
    elsif current_user && current_user.ssl_account.is_registered_reseller?
      @certificate_order
    else
      [@certificate_order, {:url=>:new_order}]
    end
  end

  def buy_or_get
    @certificate.is_free? ? "Get" : "Buy"
  end
end
