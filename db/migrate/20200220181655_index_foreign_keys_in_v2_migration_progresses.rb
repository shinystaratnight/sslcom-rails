class IndexForeignKeysInV2MigrationProgresses < ActiveRecord::Migration
  def change
    add_index :v2_migration_progresses, :migratable_id
    add_index :v2_migration_progresses, :source_id
  end
end
