class RenewalAttempt < ActiveRecord::Base
  belongs_to  :certificate_order
  belongs_to  :order_transaction
end
