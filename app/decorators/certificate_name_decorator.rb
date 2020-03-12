# frozen_string_literal: true

class CertificateNameDecorator < Draper::Decorator
  delegate_all

  def domain
    object.name
  end

  def http_token
    object.acme_token
  end

  def dns_token
    object.acme_token
  end

  def validated?
    !object.validated_domain_control_validations.empty?
  end

  def validation_method
    object.validation_source.presence || 'NONE'
  end

  def status
    case workflow_state
    when 'satisfied'
      'valid'
    when 'failed'
      'invalid'
    when ''
      'pending'
    else
      'processing'
    end
  end

  def workflow_state
    object&.domain_control_validations&.acme&.last&.workflow_state || ''
  end
end
