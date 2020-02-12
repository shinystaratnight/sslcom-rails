# == Schema Information
#
# Table name: renewal_notifications
#
#  id                   :integer          not null, primary key
#  body                 :text(65535)
#  recipients           :string(255)
#  subject              :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certificate_order_id :integer
#
# Indexes
#
#  index_renewal_notifications_on_certificate_order_id  (certificate_order_id)
#

class RenewalNotification < ApplicationRecord
  belongs_to :certificate_order
end
