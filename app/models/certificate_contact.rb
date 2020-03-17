# == Schema Information
#
# Table name: contacts
#
#  id                    :integer          not null, primary key
#  address1              :string(255)
#  address2              :string(255)
#  address3              :string(255)
#  assumed_name          :string(255)
#  business_category     :string(255)
#  callback_method       :string(255)
#  city                  :string(255)
#  company_name          :string(255)
#  company_number        :string(255)
#  contactable_type      :string(255)
#  country               :string(255)
#  country_code          :string(255)
#  department            :string(255)
#  domains               :text(65535)
#  duns_number           :string(255)
#  email                 :string(255)
#  ext                   :string(255)
#  fax                   :string(255)
#  first_name            :string(255)
#  incorporation_city    :string(255)
#  incorporation_country :string(255)
#  incorporation_date    :date
#  incorporation_state   :string(255)
#  last_name             :string(255)
#  notes                 :string(255)
#  phone                 :string(255)
#  phone_number_approved :boolean          default("0")
#  po_box                :string(255)
#  postal_code           :string(255)
#  registrant_type       :integer
#  registration_service  :string(255)
#  roles                 :string(255)      default("--- []")
#  saved_default         :boolean          default("0")
#  special_fields        :text(65535)
#  state                 :string(255)
#  status                :integer
#  title                 :string(255)
#  type                  :string(255)
#  workflow_state        :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  contactable_id        :integer
#  parent_id             :integer
#  user_id               :integer
#
# Indexes
#
#  index_contacts_on_16                                   (first_name,last_name,company_name,department,po_box,address1,address2,address3,city,state,country,postal_code,email,notes,assumed_name,duns_number)
#  index_contacts_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#  index_contacts_on_id_and_parent_id                     (id,parent_id)
#  index_contacts_on_id_and_type                          (id,type)
#  index_contacts_on_parent_id                            (parent_id)
#  index_contacts_on_type_and_contactable_type            (type,contactable_type)
#  index_contacts_on_user_id                              (user_id)
#

class CertificateContact < Contact
  include Comparable
  
  before_validation :set_roles
  before_destroy :replace_with_default
  after_save :set_one_default, if: 'contactable.is_a?SslAccount'
  after_update :update_child_contacts, if: 'contactable.is_a?SslAccount'
    
  validates :first_name, :last_name, :email, :phone, presence: true
  validates :email, email: true
  
  attr_accessor :update_parent  

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
  
  def set_one_default
    if saved_default
      contactable.saved_contacts.where(saved_default: true).where.not(id: id)
        .update_all(saved_default: false)
    else
      unless contactable.saved_contacts.where(saved_default: true).any?
        self.update(saved_default: true)
      end
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
