class RejectKey < ApplicationRecord
  ALGORITHMS = %w[RSA ECDSA]
  SOURCE_TYPES = %w[blacklist-openssl blacklist-openssh key-compromise]
  BIT_SIZE = [2048, 4096]

  validates :fingerprint, presence: true, on: :create
  validates :size, presence: true, on: :create, inclusion: { in: BIT_SIZE }
  validates :source, presence: true, on: :create, inclusion: { in: SOURCE_TYPES }
  validates :algorithm, presence: true, on: :create, inclusion: { in: ALGORITHMS }
end
