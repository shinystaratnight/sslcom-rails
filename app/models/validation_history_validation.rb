# == Schema Information
#
# Table name: validation_history_validations
#
#  id                    :integer          not null, primary key
#  created_at            :datetime
#  updated_at            :datetime
#  validation_history_id :integer
#  validation_id         :integer
#
# Indexes
#
#  index_validation_history_validations_on_validation_history_id  (validation_history_id)
#  index_validation_history_validations_on_validation_id          (validation_id)
#

class ValidationHistoryValidation < ApplicationRecord
  belongs_to  :validation_history
  belongs_to  :validation

  validates_uniqueness_of :validation_id, :scope=>[:validation_history_id]
end
