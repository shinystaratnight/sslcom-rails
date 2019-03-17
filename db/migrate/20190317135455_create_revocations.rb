class CreateRevocations < ActiveRecord::Migration
  def change
    create_table :revocations do |t|
      t.string                  :fingerprint
      t.string                  :status
      t.message_before_revoked  :text
      t.message_after_revoked   :text
      t.datetime                :revoked_on
      t.timestamps null: false
    end
    add_column :signed_certificates, :ejbca_username, :string
  end
end
