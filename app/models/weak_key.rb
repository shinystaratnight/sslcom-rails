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
end
