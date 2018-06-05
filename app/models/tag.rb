class Tag < ActiveRecord::Base
  belongs_to :ssl_account
  has_many   :taggings
  has_many   :orders, through: :taggings, source: :taggable, source_type: 'Order'
  has_many   :certificate_orders, through: :taggings, source: :taggable, source_type: 'CertificateOrder'
  has_many   :certificate_contents, through: :taggings, source: :taggable, source_type: 'CertificateContent'
  
  validates :name, allow_nil: false, allow_blank: false, uniqueness: {
    case_sensitive: true,
    scope: :ssl_account_id,
    message: 'Tag already exists for this team.'
  }
end