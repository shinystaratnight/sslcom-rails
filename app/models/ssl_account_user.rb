# frozen_string_literal: true

# == Schema Information
#
# Table name: ssl_account_users
#
#  id             :integer          not null, primary key
#  approval_token :string(255)
#  approved       :boolean          default("0")
#  declined_at    :datetime
#  invited_at     :datetime
#  token_expires  :datetime
#  user_enabled   :boolean          default("1")
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer          not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_ssl_account_users_on_four_fields                 (user_id,ssl_account_id,approved,user_enabled)
#  index_ssl_account_users_on_ssl_account_id              (ssl_account_id)
#  index_ssl_account_users_on_ssl_account_id_and_user_id  (ssl_account_id,user_id)
#  index_ssl_account_users_on_user_id                     (user_id)
#

class SslAccountUser < ApplicationRecord
  belongs_to  :user
  belongs_to  :unscoped_user, foreign_key: :ssl_account_id, class_name: 'UnscopedUser', inverse_of: :ssl_account_users
  belongs_to  :ssl_account

  scope :approved, ->{ where(approved: true, user_enabled: true) }
  scope :is_approved_ssl_account, ->(id){ approved.where(ssl_account_id: id) }
end
