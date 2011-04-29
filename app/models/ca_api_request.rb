class CaApiRequest < ActiveRecord::Base
  belongs_to :certificate_order

  default_scope order(:created_at.desc)

end
