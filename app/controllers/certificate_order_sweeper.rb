class CertificateOrderSweeper < ActionController::Caching::Sweeper
  observe CertificateOrder # This sweeper is going to keep an eye on the CertificateOrder model

  # If our sweeper detects that a CertificateOrder was created call this
  def after_create(certificate_order)
    expire_cache_for(certificate_order)
  end

  # If our sweeper detects that a CertificateOrder was updated call this
  def after_update(certificate_order)
    expire_cache_for(certificate_order)
  end

  # If our sweeper detects that a CertificateOrder was deleted call this
  def after_destroy(certificate_order)
    expire_cache_for(certificate_order)
  end

  private

  def expire_cache_for(certificate_order)
    expire_fragment('admin_header_certs_status')
  end
end