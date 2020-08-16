module Api
  module V1
    class ApiAcmeRequestsController < APIController
      prepend_view_path 'app/views/api/v1/api_acme_requests'
      before_action :set_database, if: -> { request.host=~/^sandbox/ || request.host=~/^sws-test/ || request.host=~/ssl.local$/ }
      before_action :set_test, :record_parameters

      rescue_from Exception do |exception|
        render_500_error exception
      end

      rescue_from ActiveRecord::RecordInvalid do
        InvalidApiAcmeRequest.create parameters: params, response: @result.to_json
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
        data = certificate_names.empty? ? certificate_names : certificate_names.decorate
        render json: data, each_serializer: CertificateNameSerializer, fields: %i[domain http_token dns_token validated], status: :ok
      end

      def validation_status
        persist
        if certificate_name_for_domain
          render json: certificate_name_for_domain.decorate, serializer: CertificateNameSerializer, fields: %i[validation_source status], status: :ok
        elsif domain = params[:domain]
          errors = { errors: [parameters: "no order matching #{domain} found"] }
          render_errors(errors, :not_acceptable)
        else
          errors = { errors: [parameters: 'domain is required'] }
          render_errors(errors, :not_acceptable)
        end
      end

      # Verify the External Account Binding (EAB) and check that the account is in good standing to issue certificates
      # Good standing verification includes:
      #   - account is not locked
      #   - TO BE APPROVED: the step to verify that the account has a billing profile or enough account balance should be
      #                     moved to acme/domain_preflight endpoint because no domain is passed to this endpoint.
      def account_preflight
        payload_data = Base64.urlsafe_decode64(JSON.parse(request.body)['payload'])
        external_account = JSON.parse(payload_data)['externalAccountBinding']
        kid = JSON.parse(Base64.urlsafe_decode64(external_account['protected']))['kid']

        api_credential = ApiCredential.find_by(account_key: kid.to_s)
        hmac = api_credential.hmac_key

        decoded_key = Base64.urlsafe_decode64(hmac)
        data = "#{external_account['protected']}.#{external_account['payload']}.#{external_account['signature']}"

        begin
          # Set true, in third argument, for verification
          JWT.decode data, decoded_key, true
        rescue StandardError => e
          return { status: 'error', message: 'failed to verify eab.\n' + e.message }
        end

        ssl_account = api_credential.ssl_account
        account_is_locked = ssl_account.ssl_account_users.map(&:user_enabled).include?(false)

        if account_is_locked
          { status: 'error', message: 'this account is locked.' }
        else
          { status: 'success' }
        end
      end

      private

      def certificate_names
        @result.certificate_order.certificate_content.certificate_names || CertificateName.none
      end

      def certificate_name_for_domain
        certificate_names.order(:created_at).where('name LIKE ?', "%#{params[:domain]}%").last if params[:domain]
      end

      def record_parameters
        @result = klass.new(api_acme_request) do |result|
          result.debug ||= params.fetch(:debug, false)
          result.action ||= params[:action]
          result.test = @test
          result.request_url = request.url
          result.parameters = params.to_utf8.to_json
          result.raw_request = request.raw_post.force_encoding('ISO-8859-1').encode('UTF-8')
          result.request_method = request.request_method
        end
      end

      def api_acme_request
        _wrap_parameters(params)['api_acme_request'] || params[:api_acme_request]
      end

      def klass
        case params[:action]
        when 'retrieve_hmac'
          ApiAcmeRetrieveCredential
        when 'retrieve_credentials'
          ApiAcmeRetrieveHmac
        when 'validations_info', 'validation_status'
          ApiAcmeRetrieveValidations
        end
      end

      def set_template(filename)
        @template = File.join('api', 'v1', 'api_acme_requests', filename)
      end

      def persist
        @result.validate!
        @result.save
      end
    end
  end
end
