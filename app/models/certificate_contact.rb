class CertificateContact < Contact
  include Comparable
  
  validates_presence_of  :first_name, :last_name, :email, :phone, :roles
  validates :email, email: true

  easy_roles :roles

  def <=>(contact)
    [first_name, last_name, email] <=> [contact.first_name, contact.last_name,
      contact.email]
  end
end
