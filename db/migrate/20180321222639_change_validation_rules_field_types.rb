class ChangeValidationRulesFieldTypes < ActiveRecord::Migration
  def change
    change_column :validation_rules, :applicable_validation_methods, :text
    change_column :validation_rules, :required_validation_methods, :text
    change_column :validation_rules, :notes, :text
  end
end
