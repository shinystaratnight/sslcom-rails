# == Schema Information
#
# Table name: embark_authentication_users
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  first_name             :string(255)
#  last_name              :string(255)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  time_zone              :string(255)
#  invited_by_id          :integer
#
# Indexes
#
#  index_embark_authentication_users_on_email                 (email) UNIQUE
#  index_embark_authentication_users_on_reset_password_token  (reset_password_token) UNIQUE
#
module Pillar
  module Authentication
    class User < ApplicationRecord
      # devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :masqueradable

      # has_one_attached :avatar

      validates :first_name, presence: true
      validates :last_name, presence: true

      has_many :account_users, dependent: :destroy
      has_many :accounts, through: :account_users, dependent: :destroy
      has_many :owned_accounts, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
      has_one :default_account, -> { where(default: true) }, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

      after_create :create_default_account

      def create_default_account
        uid = Pillar::Authentication::Account.generate_unique_id
        account = accounts.new(owner: self, name: uid, unique_id: uid, default: true)
        account.account_users.new(user: self, admin: true)
        account.save!
        account
      end

      def name
        "#{first_name} #{last_name}"
      end
    end
  end
end
