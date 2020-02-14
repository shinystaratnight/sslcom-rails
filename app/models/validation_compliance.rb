# == Schema Information
#
# Table name: validation_compliances
#
#  id          :integer          not null, primary key
#  description :string(255)
#  document    :string(255)
#  section     :string(255)
#  version     :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class ValidationCompliance < ApplicationRecord
end
