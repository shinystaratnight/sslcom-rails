class AddToDomainControlValidations < ActiveRecord::Migration
  def self.up
    change_table :domain_control_validations do |t|
      t.string :failure_action
    end
  end

  def self.down
    change_table :domain_control_validations do |t|
      t.remove :failure_action
    end
  end
end
