class LegacyV2UserMapping < ActiveRecord::Base
  belongs_to  :user_mappable, :polymorphic => true

  def customer
    OldSite::Customer.unscoped.find self.old_user_id
  end
end
