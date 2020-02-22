# frozen_string_literal: true

module Api
  module V1
    class TeamsController < APIController
      before_action :api_access?

      def add_contact
        @result = CertificateContact.create(params
          .merge(contactable_id: @team.id, contactable_type: 'SslAccount')
          .permit(permit_contact_params))
        render_200_status_noschema
      end

      def add_registrant
        @result = Registrant.create(params
          .merge(contactable_id: @team.id, contactable_type: 'SslAccount')
          .merge(registrant_type: Registrant.registrant_types.key(params[:registrant_type].to_i))
          .permit(permit_contact_params.push(:registrant_type)))
        render_200_status_noschema
      end

      def add_billing_profile
        @result = @team.billing_profiles.create(
          params.permit(BillingProfile::REQUIRED_COLUMNS.map(&:to_sym))
        )
        render_200_status_noschema
      end

      def saved_contacts
        json = serialize_models(@team.saved_contacts)
        render json: json, status: :ok
      end

      def saved_registrants
        json = serialize_models(@team.saved_registrants)
        render json: json, status: :ok
      end

      private

      def permit_contact_params
        %i[title first_name last_name company_name department po_box address1
           address2 address3 city state country postal_code email phone ext fax
           roles contactable_id contactable_type ]
      end
    end
  end
end
