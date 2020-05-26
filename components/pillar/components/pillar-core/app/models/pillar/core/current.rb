module Pillar
  module Core
    class Current < ActiveSupport::CurrentAttributes
      attribute :user, :account, :request_id, :user_agent, :ip_address

      resets do
        Time.zone = nil
        @account_user = nil
      end

      def user=(value)
        super
        Time.zone = Time.find_zone(value&.time_zone)
      end
    end
  end
end
