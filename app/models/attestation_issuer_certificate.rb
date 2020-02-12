# == Schema Information
#
# Table name: signed_certificates
#
#  id                        :integer          not null, primary key
#  address1                  :string(255)
#  address2                  :string(255)
#  body                      :text(65535)
#  common_name               :string(255)
#  country                   :string(255)
#  decoded                   :text(65535)
#  effective_date            :datetime
#  ejbca_username            :string(255)
#  expiration_date           :datetime
#  ext_customer_ref          :string(255)
#  fingerprint               :string(255)
#  fingerprintSHA            :string(255)
#  locality                  :string(255)
#  organization              :string(255)
#  organization_unit         :text(65535)
#  parent_cert               :boolean
#  postal_code               :string(255)
#  revoked_at                :datetime
#  serial                    :text(65535)      not null
#  signature                 :text(65535)
#  state                     :string(255)
#  status                    :text(65535)      not null
#  strength                  :integer
#  subject_alternative_names :text(65535)
#  type                      :string(255)
#  url                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  ca_id                     :integer
#  certificate_content_id    :integer
#  certificate_lookup_id     :integer
#  csr_id                    :integer
#  parent_id                 :integer
#  registered_agent_id       :integer
#
# Indexes
#
#  index_signed_certificates_cn_u_b_d_ecf_eu            (common_name,url,body,decoded,ext_customer_ref,ejbca_username)
#  index_signed_certificates_on_3_cols                  (common_name,strength)
#  index_signed_certificates_on_ca_id                   (ca_id)
#  index_signed_certificates_on_certificate_content_id  (certificate_content_id)
#  index_signed_certificates_on_certificate_lookup_id   (certificate_lookup_id)
#  index_signed_certificates_on_common_name             (common_name)
#  index_signed_certificates_on_csr_id                  (csr_id)
#  index_signed_certificates_on_csr_id_and_type         (csr_id,type)
#  index_signed_certificates_on_ejbca_username          (ejbca_username)
#  index_signed_certificates_on_fingerprint             (fingerprint)
#  index_signed_certificates_on_id_and_type             (id,type)
#  index_signed_certificates_on_parent_id               (parent_id)
#  index_signed_certificates_on_registered_agent_id     (registered_agent_id)
#  index_signed_certificates_on_strength                (strength)
#  index_signed_certificates_t_cci                      (type,certificate_content_id)
#
# Foreign Keys
#
#  fk_rails_...                                   (ca_id => cas.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_signed_certificates_certificate_content_id  (certificate_content_id => certificate_contents.id) ON DELETE => restrict ON UPDATE => restrict
#

class AttestationIssuerCertificate < SignedCertificate
  belongs_to :certificate_content
end
