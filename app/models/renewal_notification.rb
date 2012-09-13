class RenewalNotification < ActiveRecord::Base
  belongs_to :certificate_order
end
