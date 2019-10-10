class AddDomainControlValidationIndex < ActiveRecord::Migration
  def change
    add_index :domain_control_validations, [:workflow_state]
  end
end
