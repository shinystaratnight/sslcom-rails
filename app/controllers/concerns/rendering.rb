# frozen_string_literal: true

require 'active_support/concern'
module Rendering
  extend ActiveSupport::Concern

  protected

  def error(status, code, message)
    json = { response_type: 'ERROR', response_code: code, message: message }.to_json
    render json: json, status: status
  end

  def render_errors(errors, status)
    messages = errors.map { |_k, v| v }
    json = { errors: messages }
    render json: json, status: status
  end

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

  def render_unathorized
    render json: { error: I18n.t('error.invalid_api_credentials') }, status: :unauthorized
  end

  def json_render_not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def render_500_error(err)
    logger.error err.message
    err.backtrace.each { |line| logger.error line }
    error(500, 500, 'server error')
  end
end
