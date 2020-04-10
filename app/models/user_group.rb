# == Schema Information
#
# Table name: user_groups
#
#  id             :integer          not null, primary key
#  description    :text(65535)
#  name           :string(255)
#  notes          :text(65535)
#  roles          :string(255)      default("--- []")
#  ssl_account_id :integer
#
# Indexes
#
#  index_user_groups_on_ssl_account_id  (ssl_account_id)
#

class UserGroup < ApplicationRecord
  belongs_to :ssl_account
  has_and_belongs_to_many :users
  easy_roles :roles
end
