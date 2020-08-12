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
require 'rails_helper'
describe Csr do
  describe '.is_reject_key?' do
    context 'debian weak keys' do
      context 'blacklist-openssl' do
        it 'is rejected (2048)' do
          csr = create(:csr, :body_2048)
          weak_key = create(:weak_key, :bit_2048)
          Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + weak_key.fingerprint)
          expect(csr.is_reject_key?).to eq true
        end

        it 'is rejected (4096)' do
          csr = create(:csr, :body_4096)
          weak_key = create(:weak_key, :bit_4096)
          Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + weak_key.fingerprint)
          expect(csr.is_reject_key?).to eq true
        end

        it 'is not rejected' do
          csr = create(:csr)
          create_list(:weak_key, 3, :bit_2048)
          create_list(:weak_key, 3, :bit_4096)
          expect(csr.is_reject_key?).to eq false
        end
      end
    end

    context 'compromised keys' do
      it 'is rejected (2048)' do
        csr = create(:csr, :body_2048)
        compromised_key = create(:compromised_key, :bit_2048)
        Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + compromised_key.fingerprint)
        expect(csr.is_reject_key?).to eq true
      end

      it 'is rejected (4096)' do
        csr = create(:csr, :body_4096)
        compromised_key = create(:compromised_key, :bit_4096)
        Digest::SHA1.stubs(:hexdigest).with("Modulus=#{csr.public_key.n.to_s(16)}\n").returns('a' * 20 + compromised_key.fingerprint)
        expect(csr.is_reject_key?).to eq true
      end

      it 'is not rejected' do
        csr = create(:csr)
        create_list(:compromised_key, 3, :bit_2048)
        create_list(:compromised_key, 3, :bit_4096)
        expect(csr.is_reject_key?).to eq false
      end
    end
  end
end
