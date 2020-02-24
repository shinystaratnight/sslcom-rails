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
    object.domain_control_validations.exists?(workflow_state: 'satisfied')
  end

  def validation_method
    object.validation_source.presence || ''
  end

  def status
    validated? ? 'valid' : 'processing'
  end
end
