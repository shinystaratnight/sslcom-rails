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
    case work_flow_state
    when 'satisfied'
      'valid'
    when 'failed'
      'invalid'
    else
      'processing'
    end
  end

  def work_flow_state
    object.validated_domain_control_validations.work_flow_state
  end
end
