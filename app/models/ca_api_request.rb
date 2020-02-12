# frozen_string_literal: true

class CaApiRequest < ApplicationRecord
  belongs_to :api_requestable, polymorphic: true

  default_scope { order('created_at desc') }

  def success?
    return !!(response=~/errorCode=0/ or response=~/\A0\n/) if(new_record?)

    Rails.cache.fetch("#{cache_key}/success", expires_in: 24.hours) do
      !!(response =~ /errorCode=0/ || response =~ /\A0\n/)
    end
  end

  def parameters_to_hash
    return JSON.parse self.parameters if(new_record?)

    Rails.cache.fetch("#{cache_key}/parameters_to_hash", expires_in: 24.hours) do
      JSON.parse self.parameters
    end
  end

  def redacted_parameters
    return parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]') if(new_record?)

    Rails.cache.fetch("#{cache_key}/redacted_parameters", expires_in: 24.hours) do
      parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]')
    end
  end

  private

  def invalid_api_credentials
    I18n.t('error.invalid_api_credentials')
  end

  def missing_account_key_or_secret_key
    I18n.t('errror.missing_account_key_or_secret_key')
  end
end
