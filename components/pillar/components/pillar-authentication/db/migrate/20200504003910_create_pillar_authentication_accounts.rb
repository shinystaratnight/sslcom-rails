class CreatePillarAuthenticationAccounts < ActiveRecord::Migration#[6.0]
  def change
    create_table :pillar_authentication_accounts do |t|
      t.string :name
      t.text :description
      t.string :unique_id, foreign_key: false
      t.integer :owner_id, foreign_key: false
      t.boolean :default
      t.integer :status

      t.timestamps
    end
  end
end
