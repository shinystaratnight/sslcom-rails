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

FactoryBot.define do
  factory :u2f do
    nick_name   { 'u2f_name' }
    key_handle  { 'u2f_handle' }
    association :user
  end
end
