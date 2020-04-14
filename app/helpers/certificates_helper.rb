module CertificatesHelper
  def certificate_crumbs
    crumb = link_to 'ssl certificates', certificates_path
    crumb << ' :: '
    crumb << if @certificate.is_ucc? || @certificate.is_wildcard?
               link_to('wildcard or ucc', wildcard_or_ucc_certificates_url)
             else
               link_to('single domain', single_domain_certificates_url)
             end
    crumb << " :: #{@certificate.title}"
  end

  def new_certificate_params
    if @certificate_order.is_unused_credit?
      [@certificate_order, { url: :update_csr_certificate_order }]
    elsif current_user&.ssl_account&.is_registered_reseller?
      @certificate_order
    else
      [@certificate_order, { url: :new_order }]
    end
  end

  def buy_or_get
    @certificate.is_free? ? 'Get' : 'Buy'
  end

  def pricing(certificate)
    last_duration_pricing certificate
  end

  def last_duration_pricing(certificate)
    years = certificate.last_duration.value.to_i / 365
    years = 1 unless years > 0
    p = lambda do |cert|
      if cert.is_ucc?
        cert.first_domains_tiers.last.price * 3
      else
        cert.last_duration.price
      end
    end
    price = p.call(certificate)
    orig_price = p.call(certificate.untiered)
    actual = (price / years).format
    unless certificate.is_dv?
      orig = (certificate.tiered? ?
       (orig_price / years).format : nil)
    end
    render partial: 'pricing', locals: { actual: actual, orig: orig }
  end

  def first_duration_pricing
    actual = certificate.first_duration.price.format
    unless certificate.is_dv?
      orig = (certificate.tiered? ?
       certificate.untiered.first_duration.price.format : nil)
    end
    render partial: 'pricing', locals: { actual: actual, orig: orig }
  end
end
