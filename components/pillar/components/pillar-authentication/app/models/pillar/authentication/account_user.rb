# == Schema Information
#
# Table name: embark_authentication_account_users
#
#  id         :bigint           not null, primary key
#  roles      :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer
#  user_id    :integer
#
module Pillar
  module Authentication
    class AccountUser < ApplicationRecord
      belongs_to :account
      belongs_to :user

      validates :user_id, uniqueness: { scope: :account_id }

      # Add account roles to this line
      ROLES = [:admin, :member].freeze

      # Store the roles in the roles json column and cast to booleans
      store_accessor :roles, *ROLES

      ROLES.each do |role|
        scope role, -> { where("roles @> ?", { role => true }.to_json) }

        define_method(:"#{role}=") { |value| super ActiveRecord::Type::Boolean.new.cast(value) }
        define_method(:"#{role}?") { send(role) }
      end

      def active_roles
        ROLES.select { |role| send(:"#{role}?") }.compact
      end
    end
  end
end
