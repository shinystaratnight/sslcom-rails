class Contact < ActiveRecord::Base
  belongs_to  :contactable, :polymorphic => true
  include V2MigrationProgressAddon
end
