class CreateV2MigrationProgress < ActiveRecord::Migration
  def self.up
    create_table :v2_migration_progresses do |t|
      t.string      :source_table_name
      t.integer     :source_id
      t.references  :migratable, :polymorphic=>true
      t.datetime    :migrated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :v2_migration_progresses
  end
end
