class CreatePillarAuthorityBlocklistEntryExemptions < ActiveRecord::Migration#[6.0]
  def change
    create_table :pillar_authority_blocklist_entry_exemptions do |t|
      t.integer :blocklist_entry_id, foreign_key: false
      t.integer :account_id, foreign_key: false

      t.timestamps
    end
  end
end
