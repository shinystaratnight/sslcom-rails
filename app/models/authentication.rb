class Authentication < ApplicationRecord
  belongs_to :user
  validates :user_id, :uid, :provider, :presence => true
  validates_uniqueness_of :uid, :scope => :provider
end
