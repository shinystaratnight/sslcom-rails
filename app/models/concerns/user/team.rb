# frozen_string_literal: true

module Concerns
  module User
    module Team
      extend ActiveSupport::Concern
      extend Memoist

      def total_teams_owned(user_id = nil)
        user = self_or_other(user_id)
        user.assignments.includes(:ssl_account).where(role_id: Role.get_owner_id).map(&:ssl_account).uniq.compact
      end
      memoize :total_teams_owned

      def total_teams_admin(user_id = nil)
        user = self_or_other(user_id)
        user.assignments.includes(:ssl_account).where(role_id: Role.get_account_admin_id).map(&:ssl_account).uniq.compact
      end
      memoize :total_teams_admin

      def total_teams_can_manage_users(user_id = nil)
        user = self_or_other(user_id)
        user.assignments.includes(:ssl_account).where(role_id: Role.can_manage_users).map(&:ssl_account).uniq.compact
      end
      memoize :total_teams_can_manage_users

      def total_teams_cannot_manage_users(user_id = nil)
        user = self_or_other(user_id)
        user.ssl_accounts - user.assignments.where(role_id: Role.cannot_be_managed).map(&:ssl_account).uniq.compact
      end
      memoize :total_teams_cannot_manage_users

      def max_teams_reached?(user_id = nil)
        user = self_or_other(user_id)
        total_teams_owned(user.id).count >= user.max_teams
      end

      def set_default_team(ssl_account)
        update(main_ssl_account: ssl_account.id) if ssl_accounts.include?(ssl_account)
      end

      def can_manage_team_users?(target_ssl = nil)
        assignments.exists?(
          ssl_account_id: (target_ssl.nil? ? ssl_account : target_ssl).id,
          role_id: Role.can_manage_users
        )
      end
    end
  end
end
