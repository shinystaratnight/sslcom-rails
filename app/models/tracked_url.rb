class TrackedUrl < ActiveRecord::Base
  has_many  :trackings
  has_many  :visitor_tokens, :through=>:trackings
end
