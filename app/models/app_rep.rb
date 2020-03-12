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
#  phone_number_approved :boolean          default(FALSE)
#  po_box                :string(255)
#  postal_code           :string(255)
#  registrant_type       :integer
#  registration_service  :string(255)
#  roles                 :string(255)      default("--- []")
#  saved_default         :boolean          default(FALSE)
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

class AppRep < Contact

  belongs_to :ssl_account

  CALLBACK_METHODS=['t','l']
  validates :callback_method,
            inclusion: {in: CALLBACK_METHODS,
                        message: "needs to one of the following: #{CALLBACK_METHODS}"}
  validate  :phone, if: lambda{|a|a.callback_method=='t'}
end
