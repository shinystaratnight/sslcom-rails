class ContactValidationHistory < ApplicationRecord
  belongs_to  :validation_history
  belongs_to  :contact
end
