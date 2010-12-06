class VisitorToken < ActiveRecord::Base
  validates_presence_of :guid

  belongs_to   :user
  has_one   :affilite
  has_many  :trackings
  has_many  :tracked_urls, :through=>:trackings
end
