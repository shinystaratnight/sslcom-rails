module Pillar
  module Authentication
    module CommonController
      extend ActiveSupport::Concern

      included do
        before_action do
          # Current.user_id
          # Current.account_id
        end
      end
    end
  end
end
