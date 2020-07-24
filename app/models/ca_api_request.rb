# == Schema Information
#
# Table name: ca_api_requests
#
#  id                   :integer          not null, primary key
#  api_requestable_type :string(191)
#  ca                   :string(255)
#  certificate_chain    :text(65535)
#  method               :string(255)
#  parameters           :text(65535)
#  raw_request          :text(65535)
#  request_method       :text(65535)
#  request_url          :text(65535)
#  response             :text(16777215)
#  type                 :string(191)
#  username             :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  api_requestable_id   :integer
#  approval_id          :string(255)
#
# Indexes
#
#  index_ca_api_requests_on_api_requestable                          (api_requestable_id,api_requestable_type)
#  index_ca_api_requests_on_approval_id                              (approval_id)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

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
    I18n.t('error.missing_account_key_or_secret_key')
  end
end
