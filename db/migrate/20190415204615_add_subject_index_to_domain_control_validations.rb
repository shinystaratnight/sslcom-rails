class AddSubjectIndexToDomainControlValidations < ActiveRecord::Migration
  def change
    add_index :domain_control_validations, [:subject]
  end
end
