class CreateValidationRules < ActiveRecord::Migration
  def self.up
    create_table :validation_rules, force: true do |t|
      t.string      :description
      t.string      :operator
      t.integer     :parent_id
      t.string      :applicable_validation_methods
      t.string      :required_validation_methods
      t.string      :required_validation_methods_operator, :default=>"AND"
      t.string      :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_rules
  end
end
