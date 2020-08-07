class CertificateContact < Contact
  include Comparable

  before_validation :set_roles
  before_destroy :replace_with_default
  after_save :set_one_default, if: -> { contactable.is_a? SslAccount }
  after_update :update_child_contacts, if: -> { contactable.is_a? SslAccount }

  validates :first_name, :last_name, :email, :phone, presence: true
  validates :email, email: true
  easy_roles :roles
  attr_accessor :update_parent

  def <=>(other)
    [first_name, last_name, email] <=> [other.first_name, other.last_name, other.email]
  end

  def to_digest_key
    [first_name.capitalize, last_name.capitalize, email.downcase].join(',')
  end

  private

  def update_child_contacts
    Delayed::Job.enqueue SyncChildContactsJob.new(self.id)
  end

  def set_one_default
    if saved_default
      contactable.saved_contacts.where(saved_default: true).where.not(id: id).update_all(saved_default: false)
    else
      update(saved_default: true) unless contactable.saved_contacts.where(saved_default: true).any?
    end
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
