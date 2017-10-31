class CaaCheck < ActiveRecord::Base
  belongs_to :checkable, :polymorphic => true
end