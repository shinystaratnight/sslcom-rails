# == Schema Information
#
# Table name: validations
#
#  id             :integer          not null, primary key
#  address1       :string(255)
#  address2       :string(255)
#  city           :string(255)
#  contact_email  :string(255)
#  contact_phone  :string(255)
#  country        :string(255)
#  domain         :string(255)
#  email          :string(255)
#  first_name     :string(255)
#  label          :string(255)
#  last_name      :string(255)
#  notes          :string(255)
#  organization   :string(255)
#  phone          :string(255)
#  postal_code    :string(255)
#  state          :string(255)
#  tax_number     :string(255)
#  website        :string(255)
#  workflow_state :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class OrganizationValidation < Validation
  has_many :certificate_contents
end
