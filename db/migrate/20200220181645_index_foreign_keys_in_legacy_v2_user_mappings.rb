class IndexForeignKeysInLegacyV2UserMappings < ActiveRecord::Migration
  def change
    add_index :legacy_v2_user_mappings, :old_user_id
    add_index :legacy_v2_user_mappings, :user_mappable_id
  end
end
