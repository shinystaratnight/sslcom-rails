class ValidationHistoryValidation < ApplicationRecord
  belongs_to  :validation_history
  belongs_to  :validation

  validates_uniqueness_of :validation_id, :scope=>[:validation_history_id]
end
