class LegacyV2UserMapping < ActiveRecord::Base
  belongs_to  :user_mappable, :polymorphic => true
end
