class VisitorToken < ApplicationRecord
  validates_presence_of :guid

  belongs_to  :user
  belongs_to  :affiliate
  has_many    :trackings
  has_many    :tracked_urls, :through=>:trackings
  has_many    :orders

  GUID = :guid
end
