class CaApiRequest < ActiveRecord::Base
  belongs_to :api_requestable, polymorphic: true

  default_scope{ order("created_at desc")}

  def success?
    if new_record?
      !!(response=~/errorCode=0/ or response=~/\A0\n/) :
    else
      Rails.cache.fetch("#{cache_key}/success?") do
        !!(response=~/errorCode=0/ or response=~/\A0\n/)
      end
    end
  end

  def parameters_to_hash
    if new_record?
      JSON.parse self.parameters
    else
      Rails.cache.fetch("#{cache_key}/parameters_to_hash") do
        JSON.parse self.parameters
      end
    end
  end

  def redacted_parameters
    if new_record?
      parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]') :
    else
      Rails.cache.fetch("#{cache_key}/redacted_parameters") do
        parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]')
      end
    end
  end
end
