class DuplicateV2User < ActiveRecord::Base
  belongs_to  :user
  has_many    :legacy_v2_user_mappings, :as=>:user_mappable
end
