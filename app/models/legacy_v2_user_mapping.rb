# == Schema Information
#
# Table name: legacy_v2_user_mappings
#
#  id                 :integer          not null, primary key
#  user_mappable_type :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  old_user_id        :integer
#  user_mappable_id   :integer
#

class LegacyV2UserMapping < ApplicationRecord
  belongs_to  :user_mappable, :polymorphic => true

  def customer
    OldSite::Customer.unscoped.find self.old_user_id
  end
end
