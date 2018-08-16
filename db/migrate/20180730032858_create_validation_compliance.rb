class CreateValidationCompliance < ActiveRecord::Migration
  def change
    create_table :validation_compliances do |t|
      t.string :document
      t.string :version
      t.string :section
      t.timestamps
    end

    add_reference :domain_control_validations, :validation_compliance
    add_column :domain_control_validations, :validation_compliance_date, :datetime
  end
end
