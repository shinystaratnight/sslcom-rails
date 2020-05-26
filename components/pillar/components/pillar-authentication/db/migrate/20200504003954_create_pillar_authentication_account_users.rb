class CreatePillarAuthenticationAccountUsers < ActiveRecord::Migration#[6.0]
  def change
    create_table :pillar_authentication_account_users do |t|
      t.integer :account_id, foreign_key: false
      t.integer :user_id, foreign_key: false
      t.text :roles
      # t.json :roles

      t.timestamps
    end
  end
end
