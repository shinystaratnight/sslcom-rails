class Api::V1::ApiSslManagerRequestsController < Api::V1::APIController
  before_filter :set_test, :record_parameters

  wrap_parameters ApiSslManagerRequest, include:
      [*(
        ApiSslManagerRequest::REGISTER+
        ApiSslManagerRequest::COLLECTION
      ).uniq]

  def set_result_parameter(result, asm, message)
    if asm
      result.ref = asm.ref
      result.created_at = asm.created_at
      result.updated_at = asm.updated_at
    else
      result.message = message
    end
  end

  def register
    set_template "register"

    if @result.save
      if @obj = @result.create_ssl_manager
        if @obj.is_a?(RegisteredAgent) && @obj.errors.empty?
          set_result_parameter(@result, @obj, nil)
        elsif @obj.is_a?(String)
          set_result_parameter(@result, nil, @obj)
        else
          @result = @obj
        end
      end
    else
      InvalidApiSslManagerRequest.create parameters: params, response: @result.to_json
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def collection
    set_template "collection"

    if @result.save
      if @obj = @result.create_managed_certificates
        if @obj.is_a?(RegisteredAgent) && @obj.errors.empty?
          set_result_parameter(@result, @obj, nil)
        else
          @result = @obj
        end
      end
    else
      InvalidApiSslManagerRequest.create parameters: params, response: @result.to_json
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  private

    def record_parameters
      klass = case params[:action]
                when "register"
                  ApiSslManagerCreate
                when "collection"
                  ApiManagedCertificateCreate
              end

      @result = klass.new(params[:api_ssl_manager_request] || _wrap_parameters(params)['api_ssl_manager_request'])
      @result.debug = params[:debug] if params[:debug]
      @result.action = params[:action]
      @result.options = params[:options] if params[:options]
      @result.test = @test
      @result.request_url = request.url
      @result.parameters = params.to_json
      @result.raw_request = request.raw_post
      @result.request_method = request.request_method
    end

    def set_template(filename)
      @template = File.join("api","v1","api_ssl_manager_requests", filename)
    end
end