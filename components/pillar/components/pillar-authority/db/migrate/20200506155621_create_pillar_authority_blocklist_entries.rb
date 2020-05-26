class CreatePillarAuthorityBlocklistEntries < ActiveRecord::Migration#[6.0]
  def change
    create_table :pillar_authority_blocklist_entries do |t|
      t.string :pattern
      t.text :description
      t.string :type
      t.boolean :common_name
      t.boolean :organization
      t.boolean :organization_unit
      t.boolean :location
      t.boolean :state
      t.boolean :country
      t.boolean :san

      t.timestamps
    end
  end
end
