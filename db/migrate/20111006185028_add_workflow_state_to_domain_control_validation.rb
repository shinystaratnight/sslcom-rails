class AddWorkflowStateToDomainControlValidation < ActiveRecord::Migration
  def self.up
    add_column :domain_control_validations, :workflow_state, :string
  end

  def self.down
    remove_column :domain_control_validations, :workflow_state
  end
end
