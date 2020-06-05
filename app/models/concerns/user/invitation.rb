module Concerns
  module User
    module Invitation
      extend ActiveSupport::Concern

      def pending_account_invites?
        ssl_account_users.each do |ssl|
          return true if approval_token_valid?(ssl_account_id: ssl.ssl_account_id, skip_match: true)
        end
        false
      end

      def get_pending_accounts
        acct_invite = []
        ssl_account_users.each do |ssl|
          params = { ssl_account_id: ssl.ssl_account_id, skip_match: true }
          next unless approval_token_valid?(params)

          acct_invite << {
            acct_number: SslAccount.find_by_id(ssl.ssl_account_id).acct_number,
            ssl_account_id: ssl.ssl_account_id,
            approval_token: ssl.approval_token
          }
        end
        acct_invite
      end

      def approve_invite(params)
        ssl_acct_id = params[:ssl_account_id]
        errors = []
        if user_approved_invite?(params)
          errors << 'Invite already approved for this account!'
        else
          if approval_token_valid?(params)
            set_approval_token(params.merge(clear: true))
            ssl = approve_account(params)
            if ssl
              deliver_invite_to_account_accepted!(ssl.ssl_account)
              Assignment.where( # notify team owner and users_manager(s)
                ssl_account_id: ssl_acct_id,
                role_id: Role.get_role_ids([Role::OWNER, Role::USERS_MANAGER])
              ).map(&:user).uniq.compact.each do |for_admin|
                deliver_invite_to_account_accepted!(ssl.ssl_account, for_admin)
              end
            end
          else
            errors << 'Invite token is invalid or expired, please contact account admin!'
          end
          errors << 'Something went wrong! Please try again!' unless user_approved_invite?(params)
        end
        errors
      end

      def decline_invite(params)
        ssl = get_ssl_acct_user_for_approval(params)
        if ssl
          team = ssl.ssl_account
          SystemAudit.create(
            owner: self,
            target: team,
            action: 'Declined invitation to team (UsersController#decline_account_invite).',
            notes: "User #{login} has declined invitation to team #{team.get_team_name} (##{team.acct_number})."
          )
          ssl.update(
            approved: false,
            token_expires: nil,
            approval_token: nil,
            declined_at: DateTime.now
          )
        end
      end

      def user_approved_invite?(params)
        ssl = get_ssl_acct_user_for_approval(params)
        ssl&.approved && ssl.token_expires.nil? && ssl.approval_token.nil?
      end

      def user_declined_invite?(params)
        ssl = get_ssl_acct_user_for_approval(params)
        ssl && !ssl.approved && ssl.token_expires.nil? && ssl.approval_token.nil?
      end

      def resend_invitation_with_token(params)
        errors = []
        invite_existing_user(params)
        errors << 'Token was not renewed. Please try again' unless approval_token_valid?(params.merge(skip_match: true))
        errors
      end
    end
  end
end
