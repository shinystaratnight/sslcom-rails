# frozen_string_literal: true

# app/controllers/concerns/rendering.rb

require 'active_support/concern'

module Rendering
  extend ActiveSupport::Concern

  protected

  def error(status, code, message)
    json = { response_type: 'ERROR', response_code: code, message: message }.to_json
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

  def render_not_found(klass, identifier, key = 'id')
    render json: { error: "#{klass} not found with #{key} identifier"}
  end

  def render_unathorized
    render json: { error: 'Invalid credentials'}, status: :unauthorized
  end

  def render_400_status
    render template: @template, status: :bad_request
  end

  def render_500_error(err)
    logger.error err.message
    err.backtrace.each { |line| logger.error line }
    error(500, 500, 'server error')
  end
end
