# == Schema Information
#
# Table name: system_audits
#
#  id          :integer          not null, primary key
#  action      :string(255)
#  notes       :text(65535)
#  owner_type  :string(255)
#  target_type :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :integer
#  target_id   :integer
#
# Indexes
#
#  index_system_audits_on_4_cols                     (target_id,target_type,owner_id,owner_type)
#  index_system_audits_on_owner_id_and_owner_type    (owner_id,owner_type)
#  index_system_audits_on_target_id_and_target_type  (target_id,target_type)
#

# Used to audit actions of users or actors (owner) on targets

class SystemAudit < ApplicationRecord
  belongs_to  :owner, :polymorphic => true
  belongs_to  :target, :polymorphic => true
  acts_as_sellable :cents => :amount, :currency => false
end
