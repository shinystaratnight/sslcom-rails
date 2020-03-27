class Api::V1::ApiSslManagerRequestsController < Api::V1::APIController
  before_action :set_test, :record_parameters

  wrap_parameters ApiSslManagerRequest, include:
      [*(
        ApiSslManagerRequest::REGISTER+
        ApiSslManagerRequest::DELETE+
        ApiSslManagerRequest::COLLECTION+
        ApiSslManagerRequest::COLLECTIONS
      ).uniq]

  def set_result_parameter(result, asm, message = nil)
    if message.nil?
      result.ref = asm.ref
      result.status = asm.api_status
      result.reason = asm.reason unless asm.reason.blank?
    else
      result.status = message
    end
  end

  def index
    set_template "index"

    if @result.save
      @ssl_managers = @result.find_ssl_managers(params[:search])

      page = params[:page] || 1
      per_page = params[:per_page] || PER_PAGE_DEFAULT
      @paged_ssl_managers = paginate @ssl_managers, per_page: per_page.to_i, page: page.to_i

      if @paged_ssl_managers.is_a?(ActiveRecord::Relation)
        @results = []

        @paged_ssl_managers.each do |ssl_manager|
          result = ApiSslManagerRetrieve.new(ref: ssl_manager.ref)
          result.ip_address = ssl_manager.ip_address
          result.mac_address = ssl_manager.mac_address
          result.agent = ssl_manager.agent
          result.friendly_name = ssl_manager.friendly_name
          result.workflow_status = ssl_manager.workflow_status
          result.created_at = ssl_manager.created_at
          result.updated_at = ssl_manager.updated_at

          @results << result
        end
      end
    else
      InvalidApiSslManagerRequest.create parameters: params, response: @result.to_json
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def register
    set_template "register"

    if @result.save
      if @obj = @result.create_ssl_manager
        if @obj.is_a?(RegisteredAgent) && @obj.errors.empty?
          set_result_parameter(@result, @obj)
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

  def delete
    set_template "delete"

    if @result.save
      if @obj = @result.delete_ssl_manager
        if @obj.is_a?(String)
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

    if @result.valid?
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

  def collections
    set_template "collections"

    if @result.save
      @managed_certs = @result.find_managed_certs(params[:ssl_manager_ref], params[:search])

      page = params[:page] || 1
      per_page = params[:per_page] || PER_PAGE_DEFAULT
      @paged_managed_certs = paginate @managed_certs, per_page: per_page.to_i, page: page.to_i

      if @paged_managed_certs.is_a?(ActiveRecord::Relation)
        @results = []

        @paged_managed_certs.each do |managed_cert|
          result = ApiManagedCertificateRetrieve.new
          result.common_name = managed_cert.common_name
          result.subject_alternative_names = managed_cert.subject_alternative_names.split(',').join(', ')
          result.effective_date = managed_cert.effective_date
          result.expiration_date = managed_cert.expiration_date
          result.serial = managed_cert.serial
          result.issuer = managed_cert.issuer_dn
          result.status = managed_cert.status
          result.created_at = managed_cert.created_at
          result.updated_at = managed_cert.updated_at

          @results << result
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
                when "collections"
                  ApiManagedCertificateRetrieve
                when "delete"
                  ApiSslManagerDelete
                when "index"
                  ApiSslManagerRetrieve
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
