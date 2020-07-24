# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  action        :string(255)
#  description   :text(65535)
#  name          :string(255)
#  subject_class :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  subject_id    :integer
#
# Indexes
#
#  index_permissions_on_subject_id  (subject_id)
#

class Permission < ApplicationRecord
  # attr_accessible :title, :body
  has_and_belongs_to_many   :roles

end
