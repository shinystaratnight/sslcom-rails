# == Schema Information
#
# Table name: u2fs
#
#  id          :integer          not null, primary key
#  certificate :text(65535)
#  counter     :integer          default("0"), not null
#  key_handle  :string(255)
#  nick_name   :string(255)
#  public_key  :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  user_id     :integer
#
# Indexes
#
#  index_u2fs_on_user_id  (user_id)
#

class U2f < ApplicationRecord
  belongs_to :user

  validates :nick_name, :key_handle, presence: true
end
