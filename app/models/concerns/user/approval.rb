# frozen_string_literal: true

module Concerns
  module User
    module Approval
      extend ActiveSupport::Concern

      def generate_approval_query(params)
        ssl = get_ssl_acct_user_for_approval(params)
        "?token=#{ssl.approval_token}&ssl_account_id=#{ssl.ssl_account_id}"
      end

      def get_approval_tokens
        ssl_account_users.map(&:approval_token).uniq.compact.flatten
      end

      def approve_all_accounts(log_invite = nil)
        ssl_account_users.update_all(approved: true, token_expires: nil, approval_token: nil)
        if log_invite
          ssl_ids = assignments.where.not(role_id: Role.cannot_be_invited).map(&:ssl_account).uniq.compact.map(&:id)
          ssl_account_users.where(ssl_account_id: ssl_ids).update_all(invited_at: DateTime.now)
        end
      end

      def approval_token_not_expired?(params)
        user_approved_invite?(params) || approval_token_valid?(params.merge(skip_match: true))
      end

      def approval_token_valid?(params)
        ssl = get_ssl_acct_user_for_approval(params)
        no_ssl_account = ssl.nil?
        no_token_stored = ssl&.approval_token.nil?
        has_stored_token = ssl&.approval_token
        token_expired = has_stored_token && DateTime.parse(ssl.token_expires.to_s) <= DateTime.now
        tokens_dont_match = params[:skip_match] ? false : (has_stored_token && ssl.approval_token != params[:token])

        return false if no_ssl_account || no_token_stored || tokens_dont_match || token_expired

        true
      end

      def get_all_approved_accounts
        (is_system_admins? ? SslAccount.unscoped : approved_ssl_accounts).order('created_at desc')
      end

      def get_all_approved_teams
        (is_system_admins? ? SslAccount.unscoped : approved_teams).order('created_at desc')
      end

      def set_approval_token(params)
        ssl = get_ssl_acct_user_for_approval(params)
        ssl&.update(
          approved: false,
          token_expires: (params[:clear] ? nil : (DateTime.now + 72.hours)),
          approval_token: (params[:clear] ? nil : generate_approval_token),
          invited_at: DateTime.now,
          declined_at: nil
        )
      end
    end
  end
end
