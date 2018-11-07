class Contact < ActiveRecord::Base
  include V2MigrationProgressAddon
  include Filterable
  # include RefParam

  enum status: {
    in_progress: 1,
    pending_validation: 5,
    additional_info: 15,
    validated: 20
  }

  belongs_to :contactable, polymorphic: true
  has_many   :order_contacts, foreign_key: :parent_id, class_name: 'Contact'
  has_many   :notification_groups_subjects, as: :subjectable
  has_many   :notification_groups, through: :notification_groups_subjects
  has_many   :contact_validation_histories, dependent: :destroy
  has_many   :validation_histories, through: :contact_validation_histories
  
  attr_accessor :update_parent, :administrative_role, :billing_role, :technical_role, :validation_role
  
  serialize :special_fields
  
  ALIAS_FIELDS = {organization: :company_name, organization_unit: :department,
                  street_address_1: :address1, street_address_2: :address2,
                  street_address_3: :address3, locality: :city, state_or_province: :state, post_office_box: :po_box}
  EXCLUDED_FIELDS = %w(id roles type contactable_id contactable_type created_at updated_at notes)
  EXCLUDED_SAVED  = %w(id roles contactable_id contactable_type notes)
  SYNC_FIELDS_REQUIRED = [
    :title, :first_name, :last_name, :company_name, :department, :po_box,
    :address1, :address2, :address3, :city, :state, :country, :postal_code,
    :email, :phone, :ext, :fax
  ]
  SYNC_FIELDS = SYNC_FIELDS_REQUIRED.dup.push(:roles)
  ROLES = %w(administrative billing technical validation)
  
  before_validation :set_roles
  
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
  
  def self.get_company_fields
    [
      'company_name',
      'department',
      'company_number',
      'incorporation_date',
      'incorporation_country',
      'incorporation_state',
      'incorporation_city',
      'assumed_name',
      'business_category',
      'duns_number',
      'registration_service',
      'special_fields'
    ]
  end
  # Remove duplicate certificate contacts for current certificate content 
  # of passed certificate order.
  # Param certificate_order: object, object.id, array of objects, array of ids
  def self.clear_duplicate_co_contacts(certificate_order)
    co = case certificate_order.class.to_s
      when 'Integer'
        [CertificateOrder.find(certificate_order)]
      when 'Array'
        certificate_order.map {|o| o.is_a? Integer ? CertificateOrder.find(o) : o}
      when 'CertificateOrder'
        [certificate_order]
    end
    
    co.each do |cur_co|
      co_contacts = cur_co.certificate_content.certificate_contacts
      co_contacts.each do |c|
        check_attr = c.attributes.keep_if {|k,_| Contact::SYNC_FIELDS_REQUIRED.include?(k.to_sym)}
        c.destroy if co_contacts.where(check_attr).where.not(id: c.id).any?
      end
    end
  end
  
  def self.index_filter(params)
    filters                = {}
    p                      = params
    filter_roles           = p[:roles]
    filters[:status]       = { 'in' => p[:status].map{|s| statuses[s]} } unless p[:status].blank?
    filters[:first_name]   = { 'LIKE' => p[:first_name] } unless p[:first_name].blank?
    filters[:last_name]    = { 'LIKE' => p[:last_name] } unless p[:last_name].blank?
    filters[:email]        = { 'LIKE' => p[:email] } unless p[:email].blank?
    filters[:company_name] = { 'LIKE' => p[:company_name] } unless p[:company_name].blank?
    filters[:phone]        = { 'LIKE' => p[:phone] } unless p[:phone].blank?
    
    if filter_roles && filter_roles.any?
      filter_roles.each_with_index do |role, i|
        filters["roles_#{i}".to_sym] = { 'LIKE' => role }
      end
    end
    t = p[:team] 
    if t.present?
      found = SslAccount.where(
        "ssl_slug = ? OR acct_number = ? OR id = ? OR company_name = ?", t, t, t, t
      )
      filters[:contactable_id] = { '=' => found.first.id } if found.any?
    end
    result = filter(filters)
    result
  end

  def get_address_format
    "#{address1}, #{city}, #{state} #{postal_code}, #{country}"
  end

  def to_api_query
    {}.tap do |result|
      (ALIAS_FIELDS.keys+%w(postal_code country email)).each do |k,v|
        result.merge!(k=>self.send(k))
      end
    end
    # attributes.except(*EXCLUDED_FIELDS)
  end
  
  def set_roles
    set_roles = []
    set_roles << 'administrative' if (administrative_role && administrative_role == '1')
    set_roles << 'billing' if (billing_role && billing_role == '1')
    set_roles << 'technical' if (technical_role && technical_role == '1')
    set_roles << 'validation' if (validation_role && validation_role == '1')
    unless set_roles.empty?
      self.roles = set_roles
    end
    if roles.blank? && (type !='Registrant')
      self.roles = ['administrative']
    end
  end
  
  def self.optional_contacts?
    Settings.dynamic_contact_count == "on"
  end
end
