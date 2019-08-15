class AddWorkflowStateToSslAccounts < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :workflow_state, :string, :default => 'active'
  end
end
