class Api::V1::ApiAcmeRequestsController < Api::V1::APIController
  prepend_view_path "app/views/api/v1/api_acme_requests"

  before_filter :set_database, if: "request.host=~/^sandbox/ || request.host=~/^sws-test/ || request.host=~/ssl.local$/"
  before_filter :set_test, :record_parameters

  wrap_parameters ApiAcmeRequest, include:[*(
    ApiAcmeRequest::ACCOUNT_ACCESSORS+
    ApiAcmeRequest::CREDENTIAL_ACCESSORS
  ).uniq]

  def retrieve_hmac
    set_template "retrieve_hmac"

    if @result.valid? && @result.save
      @result.hmac_key = @result.api_credential.hmac_key
    else
      InvalidApiAcmeRequest.create parameters: params, response: @result.to_json
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def retrieve_credentials
    set_template "retrieve_credentials"

    if @result.valid? && @result.save
      @result.account_key = @result.api_credential.account_key
      @result.secret_key = @result.api_credential.secret_key
    else
      InvalidApiAcmeRequest.create parameters: params, response: @result.to_json
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  private

  def record_parameters
    klass = case params[:action]
              when "retrieve_hmac"
                ApiAcmeRetrieveCredential
              when "retrieve_credentials"
                ApiAcmeRetrieveHmac
            end

    @result = klass.new(_wrap_parameters(params)['api_acme_request'] || params[:api_acme_request])
    @result.debug ||= params[:debug] if params[:debug]
    @result.action ||= params[:action]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_utf8.to_json
    @result.raw_request = request.raw_post.force_encoding("ISO-8859-1").encode("UTF-8")
    @result.request_method = request.request_method
  end

  def set_template(filename)
    @template = File.join("api", "v1", "api_acme_requests", filename)
  end
end