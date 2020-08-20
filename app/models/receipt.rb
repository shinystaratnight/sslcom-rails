class Receipt < ApplicationRecord
  belongs_to  :order

  serialize   :confirmation_recipients
  serialize   :receipt_recipients
  serialize   :processed_recipients
end
