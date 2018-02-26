class CaApiRequest < ActiveRecord::Base
  belongs_to :api_requestable, polymorphic: true

  default_scope{ order("created_at desc")}

  def success?
    !!(response=~/errorCode=0/)
  end

  def parameters_to_hash
    JSON.parse self.parameters
  end

  def redacted_parameters
    parameters.gsub(/(&loginName=).+?(&loginPassword=).+/, '\1[REDACTED]\2[REDACTED]')
  end
end
