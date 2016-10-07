class AddSslAccountIdToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :ssl_account_id, :integer, limit: 4
    add_index  :assignments, [:user_id, :ssl_account_id, :role_id]
  end
end
