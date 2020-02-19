# frozen_string_literal: true

# issuance_type - nil, "dv_only"
class OtherDcvsSatisyJob < Struct.new(:ssl_account, :new_certificate_names, :certificate_content, :issuance_type)
  def perform
    new_certificate_names = [new_certificate_names] if new_certificate_names.is_a?(CertificateName)
    ssl_account.other_dcvs_satisfy_domain(new_certificate_names, false)
    certificate_content.certificate_order.apply_for_certificate if certificate_content.certificate.is_dv? && (issuance_type == 'dv_only') && !certificate_content.issued?
  end
end
