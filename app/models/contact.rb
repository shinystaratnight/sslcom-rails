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

class Contact < ApplicationRecord
  include V2MigrationProgressAddon
  include Filterable
  include Workflow
  # include RefParam

  enum status: {
    in_progress: 1,
    pending_validation: 5,
    additional_info: 15,
    validated: 20,
    epki_agreement: 25,
    pending_epki: 30
  }

  belongs_to :contactable, polymorphic: true
  has_many   :order_contacts, foreign_key: :parent_id, class_name: 'Contact'
  has_many   :notification_groups_subjects, as: :subjectable
  has_many   :notification_groups, through: :notification_groups_subjects
  has_many   :contact_validation_histories, dependent: :destroy
  has_many   :validation_histories, through: :contact_validation_histories
  belongs_to  :parent, class_name: "Contact"

  attr_accessor :update_parent, :administrative_role, :billing_role, :technical_role, :validation_role, :epki_agreement_request

  serialize :special_fields
  serialize :domains

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

  workflow do
    state :new do
      event :provide_info, :transitions_to => :info_provided
      event :cancel, :transitions_to => :canceled
      event :issue, :transitions_to => :issued
      event :reset, :transitions_to => :new
      event :validate, :transitions_to => :validated
      event :pend_validation, :transitions_to => :pending_validation
    end

    state :pending_validation do
      event :validate, :transitions_to => :validated
      event :reject, :transitions_to => :rejected
      event :refund, :transitions_to => :refunded
      event :charge_back, :transitions_to => :charged_back
    end

    state :pending_callback do
      event :callback, :transitions_to => :callback_satisfied
      event :validate, :transitions_to => :validated
      event :pend_validation, :transitions_to => :pending_validation
      event :reject, :transitions_to => :rejected
    end

    state :callback_satisfied do
    end
  end

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
        "ssl_slug = ? OR acct_number = ? OR id = ? OR LOWER(company_name) LIKE LOWER(?)", t, t, t, "%#{t}%"
      )
      filters[:contactable_id] = { '=' => found.first.id } if found.any?
    end
    result = filter(filters)
    result
  end

  def contact_iv?
    type == 'IndividualValidation' && contactable_type == 'SslAccount'
  end

  def contact_ov?
    type == 'Registrant' && contactable_type == 'SslAccount'
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

  def show_domains?
    epki_agreement? || pending_epki?
  end
end
