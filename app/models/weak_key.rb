# == Schema Information
#
# Table name: weak_keys
#
#  id        :integer          not null, primary key
#  algorithm :string(255)
#  sha1_hash :string(255)
#  size      :integer
#
# Indexes
#
#  index_weak_keys_on_sha1_hash  (sha1_hash)
#

class WeakKey < ApplicationRecord
  def self.add_csr(csr)
    fingerprint = Digest::SHA1.hexdigest "Modulus=#{csr.public_key.n.to_s(16)}\n"
    WeakKey.find_or_create_by({ sha1_hash: fingerprint[20..-1], size: csr.public_key.n.num_bits})
  end

  def self.present?(csr)
    fingerprint = Digest::SHA1.hexdigest "Modulus=#{csr.public_key.n.to_s(16)}\n"
    WeakKey.where({ sha1_hash: fingerprint[20..-1], size: csr.public_key.n.num_bits}).present?
  end
end
