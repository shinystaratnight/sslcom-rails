class CreateRevocations < ActiveRecord::Migration
  def change
    create_table :revocations do |t|
      t.string                  :fingerprint
      t.string                  :replacement_fingerprint
      t.string                  :status
      t.text                    :message_before_revoked
      t.text                    :message_after_revoked
      t.datetime                :revoked_on
      t.timestamps null: false
    end
    add_column :signed_certificates, :ejbca_username, :string

    add_index :revocations, [:fingerprint]
    add_index :revocations, [:replacement_fingerprint]
  end
end
