# == Schema Information
#
# Table name: tracked_urls
#
#  id         :integer          not null, primary key
#  md5        :string(255)
#  url        :text(65535)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_tracked_urls_on_md5          (md5)
#  index_tracked_urls_on_md5_and_url  (md5,url)
#

class TrackedUrl < ApplicationRecord
  has_many  :trackings
  has_many  :visitor_tokens, :through=>:trackings
end
