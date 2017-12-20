class CertificateContact < Contact
  include Comparable
  
  validates :first_name, :last_name, :email, :phone, presence: true
  validates :city, :state, :postal_code, :country, presence: true, if: 'contactable.is_a?SslAccount'
  validates :address1, presence: true, if: 'contactable.is_a?(SslAccount) && po_box.blank?'
  validates :email, email: true
  validates :roles, presence: true, if: 'contactable.is_a?CertificateContent'

  easy_roles :roles

  def <=>(contact)
    [first_name, last_name, email] <=> [contact.first_name, contact.last_name,
      contact.email]
  end

  def to_digest_key
    [first_name.capitalize, last_name.capitalize, email.downcase].join(",")
  end
end
