# frozen_string_literal: true

module Concerns
  module User
    module Notification
      extend ActiveSupport::Concern

      def deliver_activation_confirmation_by_sysadmin!(password)
        reset_perishable_token!
        UserNotifier.activation_confirmation_by_sysadmin(self, password).deliver
      end
    
      def deliver_auto_activation_confirmation!
        reset_perishable_token!
        UserNotifier.auto_activation_confirmation(self).deliver
      end
    
      def deliver_activation_instructions!
        reset_perishable_token!
        UserNotifier.activation_instructions(self).deliver
      end
    
      def deliver_activation_confirmation!
        reset_perishable_token!
        UserNotifier.activation_confirmation(self).deliver
      end
    
      def deliver_signup_invitation!(current_user, root_url, invited_teams)
        reset_perishable_token!
        UserNotifier.signup_invitation(self, current_user, root_url, invited_teams).deliver
      end
    
      def deliver_password_reset_instructions!
        reset_perishable_token!
        UserNotifier.password_reset_instructions(self).deliver
      end
    
      def deliver_username_reminder!
        UserNotifier.username_reminder(self).deliver
      end
    
      def deliver_password_changed!
        UserNotifier.password_changed(self).deliver
      end
    
      def deliver_email_changed!(address = email)
        UserNotifier.email_changed(self, address).deliver
      end
    
      def deliver_invite_to_account!(params)
        UserNotifier.invite_to_account(self, params[:from_user], params[:ssl_account_id]).deliver
      end
    
      def deliver_invite_to_account_notify_admin!(params)
        UserNotifier.invite_to_account_notify_admin(self, params[:from_user], params[:ssl_account_id]).deliver
      end
    
      def deliver_removed_from_account!(account, current_user)
        UserNotifier.removed_from_account(self, account, current_user).deliver
      end
    
      def deliver_removed_from_account_notify_admin!(account, current_user)
        UserNotifier.removed_from_account_notify_admin(self, account, current_user).deliver
      end
    
      def deliver_leave_team!(account)
        UserNotifier.leave_team(self, account).deliver
      end
    
      def deliver_leave_team_notify_admins!(notify_user, account)
        UserNotifier.leave_team_notify_admins(self, notify_user, account).deliver
      end
    
      def deliver_invite_to_account_accepted!(account, for_admin = nil)
        UserNotifier.invite_to_account_accepted(self, account, for_admin).deliver
      end
    
      def deliver_invite_to_account_disabled!(account, current_user)
        UserNotifier.invite_to_account_disabled(self, account, current_user).deliver
      end
    
      def deliver_ssl_cert_private_key!(resource_id, host_name, custom_domain_id)
        UserNotifier.ssl_cert_private_key(self, resource_id, host_name, custom_domain_id).deliver
      end

      def deliver_generate_install_ssl!(resource_id, host_name, to_address)
        UserNotifier.generate_install_ssl(self, resource_id, host_name, to_address).deliver
      end
    
      def deliver_register_ssl_manager_to_team!(registered_agent_ref, ssl_account, auto_approve)
        auto_approve ?
            UserNotifier.auto_register_ssl_manager_to_team(self, ssl_account).deliver :
            UserNotifier.register_ssl_manager_to_team(self, registered_agent_ref, ssl_account).deliver
      end
    end
  end
end
