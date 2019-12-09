# Used to audit actions of users or actors (owner) on targets

class SystemAudit < ApplicationRecord
  belongs_to  :owner, :polymorphic => true
  belongs_to  :target, :polymorphic => true
  acts_as_sellable :cents => :amount, :currency => false
end
