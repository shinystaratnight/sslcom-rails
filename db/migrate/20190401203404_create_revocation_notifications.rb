class CreateRevocationNotifications < ActiveRecord::Migration
  def change
    create_table :revocation_notifications do |t|
      t.string  :email, unique: true
      t.text    :fingerprints
      t.string  :status
    end
  end
end
