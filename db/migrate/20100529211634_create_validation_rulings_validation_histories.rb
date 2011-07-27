class CreateValidationRulingsValidationHistories < ActiveRecord::Migration
  def self.up
    create_table :validation_rulings_validation_histories, force: true do |t|
      t.references :validation_history
      t.references :validation_ruling
      t.string     :status
      t.string     :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_rulings_validation_histories
  end
end
