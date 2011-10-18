class CaApiRequest < ActiveRecord::Base
  belongs_to :api_requestable

  default_scope order(:created_at.desc)

  def success?
    !!(response=~/^errorCode=0/)
  end
end
