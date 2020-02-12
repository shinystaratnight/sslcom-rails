# == Schema Information
#
# Table name: assignments
#
#  id             :integer          not null, primary key
#  created_at     :datetime
#  updated_at     :datetime
#  role_id        :integer
#  ssl_account_id :integer
#  user_id        :integer
#
# Indexes
#
#  index_assignments_on_role_id                                 (role_id)
#  index_assignments_on_ssl_account_id                          (ssl_account_id)
#  index_assignments_on_user_id                                 (user_id)
#  index_assignments_on_user_id_and_ssl_account_id              (user_id,ssl_account_id)
#  index_assignments_on_user_id_and_ssl_account_id_and_role_id  (user_id,ssl_account_id,role_id)
#

class Assignment < ApplicationRecord
  belongs_to  :user, touch: true
  belongs_to  :role
  belongs_to  :ssl_account, touch: true
  
  def self.users_can_manage_invoice(team)
    if team && team.is_a?(SslAccount)
      Assignment.where(
        ssl_account_id: team.id, role_id: Role.can_manage_payable_invoice
      ).map(&:user).uniq
    else
      []
    end
  end
end
