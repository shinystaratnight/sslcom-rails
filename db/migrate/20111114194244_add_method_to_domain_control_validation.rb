class AddMethodToDomainControlValidation < ActiveRecord::Migration
  def self.up
    change_table :domain_control_validations do |t|
      t.string :method
    end
  end

  def self.down
    change_table :domain_control_validations do |t|
      t.remove :method
    end
  end
end
