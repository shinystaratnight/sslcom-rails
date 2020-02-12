# == Schema Information
#
# Table name: renewal_attempts
#
#  id                   :integer          not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certificate_order_id :integer
#  order_transaction_id :integer
#
# Indexes
#
#  index_renewal_attempts_on_certificate_order_id  (certificate_order_id)
#  index_renewal_attempts_on_order_transaction_id  (order_transaction_id)
#

class RenewalAttempt < ApplicationRecord
  belongs_to  :certificate_order
  belongs_to  :order_transaction
end
