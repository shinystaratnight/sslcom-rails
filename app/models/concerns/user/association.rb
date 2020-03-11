# frozen_string_literal: true

module Concerns
  module User
    module Association
      extend ActiveSupport::Concern

      included do
        has_many :u2fs
        has_many :assignments, dependent: :destroy
        has_many :visitor_tokens
        has_many :surls
        has_many :roles, through: :assignments
        has_many :permissions, through: :roles
        has_many :legacy_v2_user_mappings, as: :user_mappable
        has_many :duplicate_v2_users
        has_many :other_party_requests
        has_many :owned_system_audits, as: :owner, class_name: 'SystemAudit'
        has_many :target_system_audits, as: :target, class_name: 'SystemAudit'
        has_many :ssl_account_users, dependent: :destroy
        has_many :ssl_accounts, through: :ssl_account_users
        has_many :certificate_orders, through: :ssl_accounts
        has_many :orders, through: :ssl_accounts
        has_many :validation_histories, through: :certificate_orders
        has_many :validations, through: :certificate_orders
        has_many :approved_ssl_account_users, ->{ where{ (approved == true) & (user_enabled == true) } }, dependent: :destroy, class_name: 'SslAccountUser'
        has_many :approved_ssl_accounts, foreign_key: :ssl_account_id, source: 'ssl_account', through: :approved_ssl_account_users
        has_many :approved_teams, foreign_key: :ssl_account_id, source: 'ssl_account', through: :approved_ssl_account_users
        has_many :refunds
        has_many :discounts, as: :benefactor, dependent: :destroy
        has_one :shopping_cart
        has_and_belongs_to_many :user_groups
        has_many  :notification_groups, through: :ssl_accounts
        has_many  :certificate_order_tokens
        has_many :messages, class_name: "Ahoy::Message", as: :user
      end
    end
  end
end
