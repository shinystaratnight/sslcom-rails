# == Schema Information
#
# Table name: surl_blacklists
#
#  id          :integer          not null, primary key
#  fingerprint :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class SurlBlacklist < ApplicationRecord
end
