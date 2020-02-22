# == Schema Information
#
# Table name: validation_rulings_validation_histories
#
#  id                    :integer          not null, primary key
#  notes                 :string(255)
#  status                :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  validation_history_id :integer
#  validation_ruling_id  :integer
#

class ValidationRulingValidationHistory < ApplicationRecord
  self.table_name="validation_rulings_validation_histories"
  belongs_to  :validation_ruling
  belongs_to  :validation_history
end
