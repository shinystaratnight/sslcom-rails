# == Schema Information
#
# Table name: csrs
#
#  id                        :integer          not null, primary key
#  body                      :text(65535)
#  challenge_password        :boolean
#  common_name               :string(255)
#  country                   :string(255)
#  decoded                   :text(65535)
#  duration                  :integer
#  email                     :string(255)
#  ext_customer_ref          :string(255)
#  friendly_name             :string(255)
#  locality                  :string(255)
#  modulus                   :text(65535)
#  organization              :string(255)
#  organization_unit         :string(255)
#  public_key_md5            :string(255)
#  public_key_sha1           :string(255)
#  public_key_sha256         :string(255)
#  ref                       :string(255)
#  sig_alg                   :string(255)
#  state                     :string(255)
#  strength                  :integer
#  subject_alternative_names :text(65535)
#  created_at                :datetime
#  updated_at                :datetime
#  certificate_content_id    :integer
#  certificate_lookup_id     :integer
#  ssl_account_id            :integer
#
# Indexes
#
#  index_csrs_cn_b_d                                     (common_name,body,decoded)
#  index_csrs_on_3_cols                                  (common_name,email,sig_alg)
#  index_csrs_on_certificate_content_id                  (certificate_content_id)
#  index_csrs_on_certificate_lookup_id                   (certificate_lookup_id)
#  index_csrs_on_common_name                             (common_name)
#  index_csrs_on_common_name_and_certificate_content_id  (certificate_content_id,common_name)
#  index_csrs_on_common_name_and_email_and_sig_alg       (common_name,email,sig_alg)
#  index_csrs_on_organization                            (organization)
#  index_csrs_on_sig_alg_and_common_name_and_email       (sig_alg,common_name,email)
#  index_csrs_on_ssl_account_id                          (ssl_account_id)
#

class ManagedCsr < Csr
  belongs_to :ssl_account
  has_many :certificate_order_managed_csrs, dependent: :destroy
end
