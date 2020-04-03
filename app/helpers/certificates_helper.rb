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
end
