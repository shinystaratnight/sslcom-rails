class CreateValidationHistoryValidations < ActiveRecord::Migration
  def self.up
    create_table :validation_history_validations, force: true do |t|
      t.references  :validation_history
      t.references  :validation
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_history_validations
  end
end
