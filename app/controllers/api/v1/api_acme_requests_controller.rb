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

      wrap_parameters ApiAcmeRequest, include: [*(ApiAcmeRequest::ACCOUNT_ACCESSORS + ApiAcmeRequest::CREDENTIAL_ACCESSORS).uniq]

      def retrieve_hmac
        set_template 'retrieve_hmac'

        if @result.valid? && @result.save
          @result.hmac_key = @result.api_credential.hmac_key
        else
          InvalidApiAcmeRequest.create parameters: acme_params, response: @result.to_json
        end
        render_200_status
      end

      def retrieve_credentials
        set_template 'retrieve_credentials'

        if @result.valid? && @result.save
          @result.account_key = @result.api_credential.account_key
          @result.secret_key = @result.api_credential.secret_key
        else
          InvalidApiAcmeRequest.create parameters: acme_params, response: @result.to_json
        end
        render_200_status
      end

      def validations_info
        if @result.save!
          response = {}
          @result.certificate_order.certificate_content.certificate_names.each do |cname|
            cc = cname.certificate_content
            data = {
              http_token: '',
              dns_token: '',
              validated: cc.all_domains_validated?
            }
            data[:validation_source] = cc.domain_control_validations.last.dcv_method if cc.all_domains_validated?
            response[cname.name] = data
          end
          render json: response, status: :ok
          return
        else
          InvalidApiAcmeRequest.create parameters: acme_params, response: @result.to_json
        end
        render_200_status
      end

      private

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
        params.permit %i[account_key secret_key debug hmac_key certificate_order_id action api_acme_request format]
      end
    end
  end
end
