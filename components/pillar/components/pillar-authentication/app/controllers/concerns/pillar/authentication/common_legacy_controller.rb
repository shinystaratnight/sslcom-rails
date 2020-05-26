module Pillar
  module Authentication
    module CommonLegacyController
      extend ActiveSupport::Concern

      included do
        before_action do
          # Current.user_id
          # Current.account_id
        end

        before_action :authorized?
        helper_method :current_user_session, :current_user, :user_signed_in?
      end

      def current_user_session
        return @current_user_session if defined?(@current_user_session)
  
        @current_user_session = UserSession.find
      end
  
      def current_user
        return @current_user if defined?(@current_user)
  
        @current_user = current_user_session&.user
      end
  
      def user_signed_in?
        current_user ? true : false
      end
  
      def authorized?
        false
      end
    end
  end
end
