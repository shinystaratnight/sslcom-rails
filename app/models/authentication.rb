# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  email      :string(255)
#  first_name :string(255)
#  last_name  :string(255)
#  nick_name  :string(255)
#  provider   :string(255)
#  uid        :string(255)
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer
#
# Indexes
#
#  index_authentications_on_user_id  (user_id)
#

class Authentication < ApplicationRecord
  belongs_to :user
  validates :user_id, :uid, :provider, :presence => true
  validates_uniqueness_of :uid, :scope => :provider
end
