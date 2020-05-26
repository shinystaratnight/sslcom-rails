module Pillar
  module Authority
    module Admin
      class BlocklistEntriesController < Pillar::Authority::Admin::ApplicationController
        include Pillar::Core::CommonCrud

        def index
          super do
            @resources.includes(:blocklist_entry_exemptions)
          end
        end

        private

        def resource_class
          Pillar::Authority::BlocklistEntry
        end

        def permitted_attributes
          params.require(:blocklist_entry).permit(:pattern, :description, :common_name, :organization, :organization_unit, :location, :state, 
                                                  :country, :san, :type, blocklist_entry_exemptions_attributes: [:_destroy, :id, :account_id])
        end

        def namespace
          [:admin]
        end
      end
    end
  end
end
