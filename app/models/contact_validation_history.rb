class ContactValidationHistory < ActiveRecord::Base
  belongs_to  :validation_history
  belongs_to  :contact
end
