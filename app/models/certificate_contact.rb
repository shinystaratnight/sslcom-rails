class CertificateContact < Contact
  include Comparable
  
  before_validation :set_roles
  before_destroy :replace_with_default
    
  validates :first_name, :last_name, :email, :phone, presence: true
  validates :city, :state, :postal_code, :country, presence: true, if: 'contactable.is_a?SslAccount'
  validates :address1, presence: true, if: 'contactable.is_a?(SslAccount) && po_box.blank?'
  validates :email, email: true
  validates :roles, presence: true
  
  attr_accessor :update_parent
  
  easy_roles :roles
  
  after_update :update_child_contacts, if: 'contactable.is_a?SslAccount'
  
  def <=>(contact)
    [first_name, last_name, email] <=> [contact.first_name, contact.last_name,
      contact.email]
  end

  def to_digest_key
    [first_name.capitalize, last_name.capitalize, email.downcase].join(",")
  end
  
  private
  
  def update_child_contacts
    Delayed::Job.enqueue SyncChildContactsJob.new(self.id)
  end
  
  # If saved/available contact is deleted, then update all child contacts to default contact
  def replace_with_default
    unless contactable.is_a?(CertificateContent)
      found = contactable.saved_contacts.where(saved_default: true)
      default = found.any? ? found.first : contactable.saved_contacts.first
      if default
        order_contacts.each do |c|
          # do not update to default if default contact already exists for certificate content
          exists = c.contactable.contacts_for_form_opt(:child).map(&:parent_id).uniq.include?(default.id)
          exists ? c.destroy : c.update(parent_id: default.id)
        end
        Delayed::Job.enqueue SyncChildContactsJob.new(default.id) if order_contacts.any?
      else
        order_contacts.each {|c| c.update(parent_id: nil)}
      end
    end
  end
end
