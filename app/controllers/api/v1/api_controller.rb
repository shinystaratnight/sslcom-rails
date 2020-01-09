# frozen_string_literal: true

require 'will_paginate/array'

module Api
  module V1
    class APIController < ActionController::API
      include SerializerHelper
      include ApplicationHelper
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

      def error(status, code, message)
        json = { response_type: 'ERROR', response_code: code, message: message }.to_json
        render json: json, status: status
      end

      def set_test
        @test = is_sandbox? || %w[test].include?(Rails.env)
      end

      def activate_authlogic
        Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::RailsAdapter.new(self)
      end

      # Note: Assess the utility and functionality of this method.
      # It does not seem to work as expected.
      def render_200_status_noschema
        json = if @result.errors.empty?
                 serialize_model(@result)['data']['attributes']
               else
                 { errors: @result.errors }
               end
        render json: json, status: :ok
      end

      def render_200_status
        render template: @template, status: :ok
      end

      def render_400_status
        render template: @template, status: :bad_request
      end

      def render_500_error(err)
        logger.error err.message
        err.backtrace.each { |line| logger.error line }
        error(500, 500, 'server error')
      end

      def set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*' if Rails.env.development? # nginx handles this in production
        headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
        headers['Access-Control-Request-Method'] = '*'
        headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
      end

      def api_access?
        ak = params[:account_key]
        sk = params[:secret_key]
        return false if ak.blank? || sk.blank?

        @team ||= SslAccount.joins(:api_credential)
                            .where(api_credential: { account_key: ak, secret_key: sk }).last
        !@team.nil?
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
