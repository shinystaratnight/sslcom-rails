require "pillar/core/application_responder"

module Pillar
  module Core
    module CommonController
      extend ActiveSupport::Concern

      included do
        layout "pillar/theme/application"

        self.responder = Pillar::Core::ApplicationResponder
        respond_to :html

        before_action do
          Current.request_id = request.uuid
          Current.user_agent = request.user_agent
          Current.ip_address = request.ip
        end
      end
    end
  end
end
