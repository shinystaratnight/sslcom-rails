# == Schema Information
#
# Table name: csr_unique_values
#
#  id           :integer          not null, primary key
#  unique_value :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  csr_id       :integer
#
# Indexes
#
#  index_csr_unique_values_on_csr_id  (csr_id)
#

class CsrUniqueValue < ApplicationRecord
  belongs_to  :csr
  has_many    :domain_control_validations

  validates :csr, presence: true
  validates_each :unique_value do |record, attr, value|
    record.errors.add(attr, "is not unique to public key SHA1 #{record.csr.public_key_sha1}") if
      Csr.joins(:csr_unique_values)
        .where('csr_unique_values.unique_value = ? AND public_key_sha1 = ?', value, record.csr&.public_key_sha1).count >= 1
  end
end
