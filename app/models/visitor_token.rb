# == Schema Information
#
# Table name: visitor_tokens
#
#  id           :integer          not null, primary key
#  guid         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  affiliate_id :integer
#  user_id      :integer
#
# Indexes
#
#  index_visitor_tokens_on_affiliate_id           (affiliate_id)
#  index_visitor_tokens_on_guid                   (guid)
#  index_visitor_tokens_on_guid_and_affiliate_id  (guid,affiliate_id)
#  index_visitor_tokens_on_user_id                (user_id)
#

class VisitorToken < ApplicationRecord
  validates_presence_of :guid

  belongs_to  :user
  belongs_to  :affiliate
  has_many    :trackings
  has_many    :tracked_urls, :through=>:trackings
  has_many    :orders

  GUID = :guid
end
