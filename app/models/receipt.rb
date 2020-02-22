# == Schema Information
#
# Table name: receipts
#
#  id                       :integer          not null, primary key
#  available_funds          :string(255)
#  confirmation_recipients  :string(255)
#  deposit_amount           :string(255)
#  deposit_created_at       :string(255)
#  deposit_description      :string(255)
#  deposit_method           :string(255)
#  deposit_reference_number :string(255)
#  line_item_amounts        :string(255)
#  line_item_descriptions   :string(255)
#  order_amount             :string(255)
#  order_created_at         :string(255)
#  order_reference_number   :string(255)
#  processed_recipients     :string(255)
#  profile_credit_card      :string(255)
#  profile_full_name        :string(255)
#  profile_last_digits      :string(255)
#  receipt_recipients       :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  order_id                 :integer
#
# Indexes
#
#  index_receipts_on_order_id  (order_id)
#

class Receipt < ApplicationRecord
  belongs_to  :order

  serialize   :confirmation_recipients
  serialize   :receipt_recipients
  serialize   :processed_recipients
end
