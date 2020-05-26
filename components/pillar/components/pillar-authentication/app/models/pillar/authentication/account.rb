# == Schema Information
#
# Table name: embark_authentication_accounts
#
#  id          :bigint           not null, primary key
#  default     :boolean
#  description :text(65535)
#  name        :string(255)
#  status      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :integer
#
module Pillar
  module Authentication
    class Account < ApplicationRecord
      # has_one_attached :avatar

      validates :name, presence: true

      belongs_to :owner, class_name: "User"
      has_many :account_users, dependent: :destroy
      has_many :users, through: :account_users

      before_create :before_create

      def self.generate_unique_id
        loop do
          uid = "a#{SecureRandom.hex(1)}-#{Time.now.to_i.to_s(32)}"
          break uid unless Pillar::Authentication::Account.exists?(unique_id: uid)
        end
      end

      def before_create
        self.unique_id = Pillar::Authentication::Account.generate_unique_id
        self.name = unique_id if name.blank?
      end

      def email
        account_users.includes(:user).order(created_at: :asc).first.user.email
      end
    end
  end
end
