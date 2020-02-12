# == Schema Information
#
# Table name: contact_validation_histories
#
#  id                    :integer          not null, primary key
#  created_at            :datetime
#  updated_at            :datetime
#  contact_id            :integer          not null
#  validation_history_id :integer          not null
#
# Indexes
#
#  index_cont_val_histories_on_contact_id_and_validation_history_id  (contact_id,validation_history_id)
#  index_contact_validation_histories_on_contact_id                  (contact_id)
#  index_contact_validation_histories_on_validation_history_id       (validation_history_id)
#

class ContactValidationHistory < ApplicationRecord
  belongs_to  :validation_history
  belongs_to  :contact
end
