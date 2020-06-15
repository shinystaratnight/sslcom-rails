module Pillar
  module Authority
    module Admin
      class ApplicationController < Pillar::Authority::ApplicationController
        include Pillar::Core::CommonController
        include Pillar::Authentication::CommonLegacyController
        layout "pillar/theme/admin"
        
        private

        def authorized?
          unless current_user&.is_super_user?
            redirect_to main_app.root_path, flash: { error: "You don't have permission to view this page" }
          end
        end
      end
    end
  end
end
