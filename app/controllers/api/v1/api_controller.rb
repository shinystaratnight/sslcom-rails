# frozen_string_literal: true

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
