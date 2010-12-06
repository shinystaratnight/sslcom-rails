class TrackedUrl < ActiveRecord::Base
  has_many  :trackings
  has_many  :visior_tokens, :through=>:trackings
end
