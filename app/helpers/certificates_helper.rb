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
#    elsif @certificate.is_free?
#      [@certificate_order, {url: :create_free_ssl}]
    elsif current_user && current_user.ssl_account.is_registered_reseller?
      @certificate_order
    else
      [@certificate_order, {:url=>:new_order}]
    end
  end

  def buy_or_get
    @certificate.is_free? ? "Get" : "Buy"
  end

  def pricing(certificate)
    last_duration_pricing certificate
  end

  def last_duration_pricing(certificate)
    years = certificate.last_duration.value.to_i/365
    years = 1 unless years > 0
    factor =  certificate.is_ucc? ? 1 : 1
    p = lambda do |certificate|
            if certificate.is_ucc?
              certificate.first_domains_tiers.last.price * 3
            else
              certificate.last_duration.price
            end
    end
    price = p.call(certificate)
    orig_price = p.call(certificate.untiered)
    actual = (price/years).format
    orig = (certificate.tiered? ?
     (orig_price/years).format : nil) unless certificate.is_dv?
    render :partial=>'pricing', :locals=>{:actual=>actual, :orig=>orig}
  end

  def first_duration_pricing
    actual = certificate.first_duration.price.format
    orig = (certificate.tiered? ?
     certificate.untiered.first_duration.price.format : nil) unless
    certificate.is_dv?
    render :partial=>'pricing', :locals=>{:actual=>actual, :orig=>orig}
  end
end
