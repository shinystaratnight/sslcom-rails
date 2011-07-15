class Contact < ActiveRecord::Base
  belongs_to  :contactable, :polymorphic => true

  validates :email, email: true
end
