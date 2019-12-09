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
