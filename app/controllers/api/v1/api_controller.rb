require 'will_paginate/array'

module Api
  module V1
    class APIController < ActionController::API
      include SerializerHelper
      include ApplicationHelper
      include Rendering
      include ActionController::Cookies
      include ActionController::HttpAuthentication::Basic::ControllerMethods
      include ActionController::Rendering
      include ActionController::ImplicitRender
      include ActionView::Rendering
      include Swagger::Blocks

      skip_before_action :verify_authenticity_token
      before_action :activate_authlogic
      before_action :set_default_request_format
      after_action  :set_access_control_headers

      TEST_SUBDOMAIN = 'sws-test'
      PER_PAGE_DEFAULT = 10

      respond_to :json

      rescue_from MultiJson::DecodeError do |exception|
        render text: exception.to_s, status: :unprocessable_entity
      end

      private

      def set_test
        @test = is_sandbox? || %w[test].include?(Rails.env)
      end

      def activate_authlogic
        Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::RailsAdapter.new(self)
      end

      def set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
        headers['Access-Control-Request-Method'] = '*'
        headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
      end

      def api_access?
        ac = ApiCredential.find_by_account_key_and_secret_key(params[:account_key], params[:secret_key])
        if ac.blank?
          @result ||= ApiUserRequest.new
          @result.errors[:login] << I18n.t('error.missing_account_key_or_secret_key')
          render_200_status_noschema
        else
          @team ||= ac.ssl_account
        end
      end

      def set_default_request_format
        request.format = :json
      end

      def nilify_empty_has_params
        return if swagger_version_header.blank?

        params.each do |key, value|
          params[key] = nil if value == '{}'
        end
      end

      def swagger_version_header
        request.headers['HTTP_SWAGGER_VERSION']
      end
    end
  end
end
