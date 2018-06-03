class Api::V1::ApiUserRequestsController < Api::V1::APIController
  before_filter :set_test, :record_parameters

  wrap_parameters ApiUserRequest, include:
      [*(ApiUserRequest::CREATE_ACCESSORS_1_4).uniq]

  def set_result_parameters(result, aur, template)
    result.login = aur.login
    result.email = aur.email
    result.account_number=aur.ssl_account.acct_number
    result.status = aur.status
    result.user_url = "#{api_domain}#{user_path(aur)}"
    result.update_attribute :response, render_to_string(:template => template)
  end

  def create_v1_4
    set_template "create_v1_4"
    if @result.save
      if @obj = @result.create_user
        if @obj.is_a?(User) && @obj.errors.empty?
          set_result_parameters(@result, @obj, @template)
          @result.account_key=@obj.ssl_account.api_credential.account_key
          @result.secret_key=@obj.ssl_account.api_credential.secret_key
        else
          @result = @obj #so that rabl can report errors
        end
      end
    else
      InvalidApiUserRequest.create parameters: params, response: @result.to_json
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def show_v1_4
    set_template "show_v1_4"
    if @result.save
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
    else
      InvalidApiUserRequest.create parameters: params, response: @result.errors.to_json
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def get_teams_v1_4
    set_template "list_teams_v1_4"
    if @result.save
      if @obj = UserSession.create(params).user
        @results = []
        if @obj.is_a?(User) && @obj.errors.empty?
          @obj.ssl_accounts.each do |team|
            result = ApiUserListTeam_v1_4.new
            result.acct_number = team.acct_number
            result.roles = team.roles
            result.created_at = team.created_at
            result.updated_at = team.updated_at
            result.status = team.status
            result.ssl_slug = team.ssl_slug
            result.company_name = team.company_name
            result.issue_dv_no_validation = @obj.is_standard? || @obj.is_validations? ? team.issue_dv_no_validation : nil
            result.billing_method = @obj.is_installer? && @obj.roles_symbols.count == 1 ? nil : team.billing_method
            @results << result
          end
        else
          @result = @obj #so that rabl can report errors
        end
      else
        @result.errors[:login] << "#{@result.login} not found or incorrect password"
      end
    else
      InvalidApiUserRequest.create parameters: params, response: @result.errors.to_json
    end
    render_200_status
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
              when "get_teams_v1_4"
                ApiUserListTeam_v1_4
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
  
  def set_template(filename)
    @template = File.join("api","v1","api_user_requests", filename)
  end
end
