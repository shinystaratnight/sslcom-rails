class CreateValidationRulings < ActiveRecord::Migration
  def self.up
    create_table :validation_rulings do |t|
      t.references  :validation_rule
      t.references  :validation_rulable, :polymorphic=>true
      t.string      :workflow_state
      t.string      :status
      t.string      :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_rulings
  end
end
