# frozen_string_literal: true

module Api
  module V1
    class ApiUserRequestsController < APIController
      before_filter :set_test, :record_parameters

      wrap_parameters ApiUserRequest, include: [*ApiUserRequest::CREATE_ACCESSORS_1_4.uniq]

      def set_result_parameters(result, aur, template)
        result.login = aur.login
        result.email = aur.email
        result.account_number = aur.ssl_account.acct_number
        result.status = aur.status
        result.user_url = "#{api_domain}#{user_path(aur)}"
        result.update_attribute :response, render_to_string(template: template)
      end

      swagger_path '/users' do
        operation :post do
          key :summary, 'Create a User'
          key :description, 'Creates a User and returns API credentials'
          key :operation, 'createUser'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'user'
          ]
          parameter do
            key :name, :login
            key :type, :string
            key :in, :query
            key :description, I18n.t(:login_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :email
            key :type, :string
            key :format, :email
            key :in, :query
            key :description, I18n.t(:email_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :password
            key :type, :string
            key :in, :query
            key :description, I18n.t(:password_param_description, scope: :documentation)
            key :required, true
          end

          response 200 do
            key :description, 'Credentials Response'
            schema do
              key :'$ref', :CredentialsResponse
            end
          end
          response :default do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end

      def create_v1_4
        set_template 'create_v1_4'
        if @result.save
          if @obj = @result.create_user
            if @obj.is_a?(User) && @obj.errors.empty?
              set_result_parameters(@result, @obj, @template)
              @result.account_key = @obj.ssl_account.api_credential.account_key
              @result.secret_key = @obj.ssl_account.api_credential.secret_key
            else
              @result = @obj # so that rabl can report errors
            end
          end
        else
          InvalidApiUserRequest.create parameters: params, response: @result.to_json
        end
        render_200_status
      rescue StandardError => e
        render_500_error e
      end

      swagger_path '/user/{login}/' do
        operation :get do
          key :summary, 'Retreive User API Credentials'
          key :description, 'A single User object with all its details. Also call this method to get the latest api credentials that are required for other resources within the SSL.com api.'
          key :operation, 'getUser'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'user'
          ]
          parameter do
            key :name, :login
            key :type, :string
            key :in, :path
            key :description, 'login used when signing in'
            key :required, true
          end
          parameter do
            key :name, :password
            key :type, :string
            key :format, :password
            key :in, :query
            key :description, 'password the user signs in with'
            key :required, true
          end

          response 200 do
            key :description, 'Credentials Response'
            schema do
              key :'$ref', :CredentialsResponse
            end
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end

      def show_v1_4
        set_template 'show_v1_4'
        if @result.save
          if @obj = UserSession.create(params.to_h).user
            # successfully charged
            if @obj.is_a?(User) && @obj.errors.empty?
              set_result_parameters(@result, @obj, @template)
              @result.account_key = @obj.ssl_account.api_credential.account_key
              @result.secret_key = @obj.ssl_account.api_credential.secret_key
              @result.available_funds = Money.new(@obj.ssl_account.funded_account.cents).format
            else
              @result = @obj # so that rabl can report errors
            end
          else
            @result.errors[:login] << "#{@result.login} not found or incorrect password"
          end
        else
          InvalidApiUserRequest.create parameters: params, response: @result.errors.to_json
        end
        render_200_status
      rescue StandardError => e
        render_500_error e
      end

      def get_teams_v1_4
        set_template 'list_teams_v1_4'
        if @result.save
          if @obj = UserSession.create(params.to_h).user
            @results = []
            if @obj.is_a?(User) && @obj.errors.empty?
              @obj.ssl_accounts.uniq.each do |team|
                result = ApiUserListTeam_v1_4.new
                result.acct_number = team.acct_number
                result.roles = team.roles
                result.created_at = team.created_at
                result.updated_at = team.updated_at
                result.status = team.status
                result.ssl_slug = team.ssl_slug
                result.company_name = team.company_name
                result.issue_dv_no_validation = @obj.is_standard? || @obj.is_validations? ? team.issue_dv_no_validation : nil
                result.billing_method = @obj.is_installer? && @obj.role_symbols.count == 1 ? nil : team.billing_method
                result.available_funds = Money.new(team.funded_account.cents).format
                result.currency = team.funded_account.currency
                result.reseller_tier = team.reseller ? team.reseller.reseller_tier : nil
                result.is_default_team = team.id == @obj.ssl_account.id
                @results << result
              end
            else
              @result = @obj # so that rabl can report errors
            end
          else
            @result.errors[:login] << "#{@result.login} not found or incorrect password"
          end
        else
          InvalidApiUserRequest.create parameters: params, response: @result.errors.to_json
        end
        render_200_status
      rescue StandardError => e
        render_500_error e
      end

      def set_default_team_v1_4
        set_template 'set_default_team_v1_4'
        if @result.save
          if @obj = UserSession.create(params.to_h).user
            @results = []
            if @obj.is_a?(User) && @obj.errors.empty?
              @ssl_account = SslAccount.find_by(acct_number: params[:acct_number])
              if @obj.is_approved_account?(@ssl_account)
                @obj.update_attribute(:default_ssl_account, @ssl_account.id)
                @result.account_key = @obj.ssl_account.api_credential.account_key
                @result.secret_key = @obj.ssl_account.api_credential.secret_key
              else
                @result.errors[:login] << "#{@result.login} not approved to #{params[:ssl_account_id]}"
              end
            else
              @result = @obj # so that rabl can report errors
            end
          else
            @result.errors[:login] << "#{@result.login} not found or incorrect password"
          end
        else
          InvalidApiUserRequest.create parameters: params, response: @result.errors.to_json
        end
        render_200_status
      rescue StandardError => e
        render_500_error e
      end

      private

      def record_parameters
        klass = case params[:action]
                when 'create_v1_4', 'update_v1_4'
                  ApiUserCreate_v1_4
                when 'show_v1_4'
                  ApiUserShow_v1_4
                when 'get_teams_v1_4'
                  ApiUserListTeam_v1_4
                when 'set_default_team_v1_4'
                  ApiUserSetDefaultTeam_v1_4
                end
        @result = klass.new(params[:api_certificate_request] || _wrap_parameters(params)['api_user_request'])
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
        @template = File.join('api', 'v1', 'api_user_requests', filename)
      end
    end
  end
end
