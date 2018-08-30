class CaApiRequest < ActiveRecord::Base
  belongs_to :api_requestable, polymorphic: true

  default_scope{ order("created_at desc")}

  def success?
    Rails.cache.fetch("#{cache_key}/success?", expires_in: 24.hours) do
      !!(response=~/errorCode=0/ or response=~/\A0\n/)
    end
  end

  def parameters_to_hash
    Rails.cache.fetch("#{cache_key}/parameters_to_hash", expires_in: 24.hours) do
      JSON.parse self.parameters
    end
  end

  def redacted_parameters
    Rails.cache.fetch("#{cache_key}/redacted_parameters", expires_in: 24.hours) do
      parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]')
    end
  end
end
