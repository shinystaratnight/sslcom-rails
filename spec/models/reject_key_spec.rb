# == Schema Information
#
# Table name: reject_keys
#
#  id          :integer          not null, primary key
#  algorithm   :string(255)
#  fingerprint :string(255)
#  size        :integer
#  source      :string(255)
#  type        :string(255)
#
# Indexes
#
#  index_reject_keys_on_fingerprint  (fingerprint)
#
require 'rails_helper'

describe RejectKey do
  ALGORITHMS = %w[RSA ECDSA]
  SOURCE_TYPES = %w[blacklist-openssl blacklist-openssh key-compromise]
  BIT_SIZE = [2048, 4096]
  
  it { should validate_presence_of(:fingerprint) }
  it { should validate_presence_of(:source) }
  it { should validate_presence_of(:size) }
  it { should validate_presence_of(:algorithm) }
  it { should validate_inclusion_of(:source).in_array(SOURCE_TYPES) }
  it { should validate_inclusion_of(:size).in_array(BIT_SIZE) }
  it { should validate_inclusion_of(:algorithm).in_array(ALGORITHMS) }
end
