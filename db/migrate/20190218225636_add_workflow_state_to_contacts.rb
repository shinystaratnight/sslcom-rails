class AddWorkflowStateToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :workflow_state, :string
  end
end
