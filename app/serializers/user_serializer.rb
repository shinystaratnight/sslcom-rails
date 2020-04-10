# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  active              :boolean          default("0"), not null
#  address1            :string(255)
#  address2            :string(255)
#  address3            :string(255)
#  avatar_content_type :string(255)
#  avatar_file_name    :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#  city                :string(255)
#  country             :string(255)
#  crypted_password    :string(255)
#  current_login_at    :datetime
#  current_login_ip    :string(255)
#  default_ssl_account :integer
#  duo_enabled         :string(255)      default("enabled")
#  email               :string(255)      not null
#  failed_login_count  :integer          default("0"), not null
#  first_name          :string(255)
#  is_auth_token       :boolean
#  last_login_at       :datetime
#  last_login_ip       :string(255)
#  last_name           :string(255)
#  last_request_at     :datetime
#  login               :string(255)      not null
#  login_count         :integer          default("0"), not null
#  main_ssl_account    :integer
#  max_teams           :integer
#  openid_identifier   :string(255)
#  organization        :string(255)
#  password_salt       :string(255)
#  perishable_token    :string(255)      not null
#  persist_notice      :boolean          default("0")
#  persistence_token   :string(255)      not null
#  phone               :string(255)
#  po_box              :string(255)
#  postal_code         :string(255)
#  single_access_token :string(255)      not null
#  state               :string(255)
#  status              :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  ssl_account_id      :integer
#
# Indexes
#
#  index_users_l_e                                    (login,email)
#  index_users_on_default_ssl_account                 (default_ssl_account)
#  index_users_on_email                               (email)
#  index_users_on_login                               (login)
#  index_users_on_login_and_email                     (login,email)
#  index_users_on_perishable_token                    (perishable_token)
#  index_users_on_ssl_account_id_and_login_and_email  (ssl_account_id,login,email)
#  index_users_on_ssl_acount_id                       (ssl_account_id)
#  index_users_on_status                              (id,status)
#  index_users_on_status_and_login_and_email          (status,login,email)
#  index_users_on_status_and_ssl_account_id           (id,ssl_account_id,status)
#


class UserSerializer < ActiveModel::Serializer
  attribute :standard_avatar_url do
    object.authenticated_avatar_url(style: :standard)
  end

  attribute :thumbnail_avatar_url do
    object.authenticated_avatar_url(style: :thumb)
  end

  attribute :large_avatar_url do
    object.authenticated_avatar_url(style: :large)
  end
end
