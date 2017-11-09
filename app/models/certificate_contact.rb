class CertificateContact < Contact
  include Comparable
  
  validates_presence_of  :first_name, :last_name, :email, :phone
  validates :city, :state, :postal_code, :country, presence: true, if: 'contactable.is_a?SslAccount'
  validates :address1, presence: true, if: 'contactable.is_a?(SslAccount) && po_box.blank?'
  validates :email, email: true
  validates :roles, presence: true, if: 'contactable.is_a?CertificateContent'

  easy_roles :roles

  def <=>(contact)
    [first_name, last_name, email] <=> [contact.first_name, contact.last_name,
      contact.email]
  end
end
