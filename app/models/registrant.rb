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

class Registrant < Contact
  
  enum registrant_type: { individual: 0, organization: 1 }
  
  after_save :set_default_status
  after_destroy :release_dependant_contacts

  validates_presence_of :contactable
  validates_presence_of :company_name, :address1, :city, :state, :postal_code, :country,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && 
        r.contactable.certificate_order.certificate.requires_company_info?
    }
  validates_presence_of :phone,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }
  validates_presence_of :title,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }
  validates_presence_of :email,
    if: Proc.new{|r|
      !r.reusable? && r.contactable &&
      r.contactable.certificate_order.certificate.is_code_signing?
    }
  validates_presence_of :first_name, :last_name,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && (
        r.contactable.certificate_order.certificate.is_client_pro? ||
        r.contactable.certificate_order.certificate.is_code_signing? ||
        r.contactable.certificate_order.certificate.is_client_enterprise? ||
        r.contactable.certificate_order.certificate.is_client_business?
      )
    }

  validates_presence_of :business_category, :company_number, :incorporation_country,
    if: Proc.new{|r|
      !r.reusable? && r.contactable && r.contactable.certificate_order.certificate.is_ev?
    }

  validates :city, :state, :country, :email, presence: true,
    if: proc { |r| r.reusable? && (r.organization? || r.individual?) }
  validates :company_name, :phone, presence: true, if: proc { |r| r.reusable? && r.organization? }
  validates :first_name, :last_name, presence: true, if: proc { |r| r.reusable? && r.individual? }

  before_validation :set_default_title
  after_save :set_one_epki_agreement

  def applies_to_certificate_order?(certificate_order)
    domains.any? do |domain|
      if certificate_order.certificate.is_smime_or_client?
        email_in_subdomain?(certificate_order.get_recipient.email, domain)
      end
    end unless domains.blank?
  end

  protected
  
  def set_default_status
    if reusable? && status.nil?
      self.in_progress!
    end
  end

  def reusable?
    contactable.is_a?(SslAccount)
  end

  def self.get_validated_registrants(team)
    Registrant.where(
      contactable_type: team.class,
      contactable_id: team.id,
      status: statuses[:validated]
    )
  end

  def filter_approved_domains(filter_domains)
    approved = []
    filter_domains.any? do |filter_domain|
      domains.any? do |domain|
        if email_in_subdomain?(filter_domain, domain)
          approved << filter_domain
        end
      end
    end
    approved
  end
  
  def filter_pending_domains(filter_domains)
    filter_domains - filter_approved_domains(filter_domains)
  end

  private

  def set_default_title
    self.title = 'Mr' if title.blank?
  end

  def set_one_epki_agreement
    if epki_agreement? && contactable.is_a?(SslAccount)
      other_epki = contactable.all_saved_contacts
        .where.not(id: self.id)
        .where(status: Contact::statuses[:epki_agreement])
      other_epki.update(:status, Contact::statuses[:validated]) if other_epki.any?
    end
  end
  
  def email_in_subdomain?(target_email, compare_with)
    DomainControlValidation.domain_in_subdomains?(
      target_email.split('@').last, compare_with
    )
  end

  def release_dependant_contacts
    Contact.where(parent_id: id).update_all(parent_id: nil)
  end
end
