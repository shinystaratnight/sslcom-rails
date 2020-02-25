# frozen_string_literal: true

module Api
  module V1
    class ApiAcmeRequestsController < APIController
      prepend_view_path 'app/views/api/v1/api_acme_requests'
      before_filter :set_database, if: 'request.host=~/^sandbox/ || request.host=~/^sws-test/ || request.host=~/ssl.local$/'
      before_filter :set_test, :record_parameters

      rescue_from Exception do |exception|
        render_500_error exception
      end

      rescue_from ActiveRecord::RecordInvalid do
        InvalidApiAcmeRequest.create parameters: acme_params, response: @result.to_json
        if @result.errors[:credential].present?
          render_unathorized
        else
          render_errors(@result.errors, :not_found)
        end
      end

      wrap_parameters ApiAcmeRequest, include: [*(ApiAcmeRequest::ACCOUNT_ACCESSORS + ApiAcmeRequest::CREDENTIAL_ACCESSORS).uniq]

      def retrieve_hmac
        set_template 'retrieve_hmac'

        persist
        @result.hmac_key = @result.api_credential.hmac_key
        render_200_status
      end

      def retrieve_credentials
        set_template 'retrieve_credentials'

        persist
        @result.account_key = @result.api_credential.account_key
        @result.secret_key = @result.api_credential.secret_key
        render_200_status
      end

      def validations_info
        persist
        render json: certificate_names,
               each_serializer: CertificateNameSerializer,
               status: :ok
      end

      private

      def certificate_names
        certificate_content.certificate_names_from_domains(certificate_content.domain) unless certificate_content.certificate_names_created?
        certificate_content.certificate_names
      end

      def certificate_content
        @result.certificate_order.certificate_content
      end

      def record_parameters
        @result = klass.new(api_acme_request) do |result|
          result.debug ||= acme_params.fetch(:debug, false)
          result.action ||= acme_params[:action]
          result.test = @test
          result.request_url = request.url
          result.parameters = acme_params.to_utf8.to_json
          result.raw_request = request.raw_post.force_encoding('ISO-8859-1').encode('UTF-8')
          result.request_method = request.request_method
        end
      end

      def api_acme_request
        _wrap_parameters(acme_params)['api_acme_request'] || acme_params[:api_acme_request]
      end

      def klass
        case acme_params[:action]
        when 'retrieve_hmac'
          ApiAcmeRetrieveCredential
        when 'retrieve_credentials'
          ApiAcmeRetrieveHmac
        when 'validations_info'
          ApiAcmeRetrieveValidations
        end
      end

      def set_template(filename)
        @template = File.join('api', 'v1', 'api_acme_requests', filename)
      end

      def acme_params
        params.permit %i[account_key secret_key debug hmac_key certificate_order_ref action api_acme_request format acme_acct_pub_key_thumbprint]
      end

      def persist
        @result.validate!
        @result.save
      end
    end
  end
end
