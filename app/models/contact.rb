class Contact < ActiveRecord::Base
  include V2MigrationProgressAddon
  
  belongs_to :contactable, polymorphic: true
  has_many   :order_contacts, foreign_key: :parent_id, class_name: 'Contact'
  
  attr_accessor :update_parent
  
  ALIAS_FIELDS = {organization: :company_name, organization_unit: :department,
                  street_address_1: :address1, street_address_2: :address2,
                  street_address_3: :address3, locality: :city, state_or_province: :state, post_office_box: :po_box}
  EXCLUDED_FIELDS = %w(id roles type contactable_id contactable_type created_at updated_at notes)
  EXCLUDED_SAVED  = %w(id roles contactable_id contactable_type notes)
  SYNC_FIELDS     = [
    :title, :first_name, :last_name, :company_name, :department, :po_box,
    :address1, :address2, :address3, :city, :state, :country, :postal_code,
    :email, :phone, :ext, :fax
  ]
  
  ALIAS_FIELDS.each do |k,v|
    alias_attribute k, v
  end
  
  SyncChildContactsJob = Struct.new(:contact_id) do
    def perform
      parent = Contact.find contact_id
      if parent
        parent.order_contacts.each do |contact|
          contact.update_attributes(
            parent.attributes.keep_if {|k,_| Contact::SYNC_FIELDS.include? k.to_sym}
          )
        end
      end
    end
  end
  
  def to_api_query
    {}.tap do |result|
      (ALIAS_FIELDS.keys+%w(postal_code country email)).each do |k,v|
        result.merge!(k=>self.send(k))
      end
    end
    # attributes.except(*EXCLUDED_FIELDS)
  end
  
  def self.optional_contacts?
    Settings.dynamic_contact_count == "on"
  end
end
