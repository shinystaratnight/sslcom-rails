class ValidationRulingValidationHistory < ActiveRecord::Base
  set_table_name  :validation_rulings_validation_histories
  belongs_to  :validation_ruling
  belongs_to  :validation_history
end
