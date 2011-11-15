class AddMethodToDomainControlValidation < ActiveRecord::Migration
  def self.up
    change_table :domain_control_validations do |t|
      t.string :dcv_method
    end
  end

  def self.down
    change_table :domain_control_validations do |t|
      t.remove :dcv_method
    end
  end
end
