class CreateLegacyV2UserMappings < ActiveRecord::Migration
  def self.up
    create_table :legacy_v2_user_mappings, force: true do |t|
      t.integer :old_user_id
      t.references :user_mappable, :polymorphic=>true
      t.timestamps
    end
  end

  def self.down
    drop_table :legacy_v2_user_mappings
  end
end
