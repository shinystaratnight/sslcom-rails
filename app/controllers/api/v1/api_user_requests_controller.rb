class Api::V1::ApiUserRequestsController < Api::V1::APIController
  before_filter :set_test, :record_parameters

  wrap_parameters ApiUserRequest, include:
      [*(ApiUserRequest::CREATE_ACCESSORS_1_4).uniq]

  def set_result_parameters(result, aur, template)
    result.login = aur.login
    result.email = aur.email
    result.account_number=aur.ssl_account.acct_number
    result.status = aur.status
    result.user_url = "https://#{Settings.community_domain}#{user_path(aur)}"
    result.update_attribute :response, render_to_string(:template => template)
  end

  def create_v1_4
    if @result.save
      @template = "api_user_requests/create_v1_4"
      if @obj = @result.create_user
        if @obj.is_a?(User) && @obj.errors.empty?
          set_result_parameters(@result, @obj, @template)
          @result.account_key=@obj.ssl_account.api_credential.account_key
          @result.secret_key=@obj.ssl_account.api_credential.secret_key
        else
          @result = @obj #so that rabl can report errors
        end
      end
      render_200_status
    else
      InvalidApiUserRequest.create parameters: params
      render_400_status
    end
  rescue => e
    render_500_error e
  end

  def show_v1_4
    if @result.save
      @template = "api_user_requests/show_v1_4"
      if @obj = UserSession.create(params).user
        # successfully charged
        if @obj.is_a?(User) && @obj.errors.empty?
          set_result_parameters(@result, @obj, @template)
          @result.account_key=@obj.ssl_account.api_credential.account_key
          @result.secret_key=@obj.ssl_account.api_credential.secret_key
          @result.available_funds=Money.new(@obj.ssl_account.funded_account.cents).format
        else
          @result = @obj #so that rabl can report errors
        end
      else
        @result.errors[:login] << "#{@result.login} not found or incorrect password"
      end
      render_200_status
    else
      InvalidApiUserRequest.create parameters: params
      render_400_status
    end
  rescue => e
    render_500_error e
  end

  private

  def record_parameters
    klass = case params[:action]
              when "create_v1_4", "update_v1_4"
                ApiUserCreate_v1_4
              when "show_v1_4"
                ApiUserShow_v1_4
            end
    @result=klass.new(params[:api_certificate_request] || _wrap_parameters(params)['api_user_request'])
    @result.debug = params[:debug] if params[:debug]
    @result.action = params[:action]
    @result.options = params[:options] if params[:options]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_json
    @result.raw_request = request.raw_post
    @result.request_method = request.request_method
  end
end
