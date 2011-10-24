class CreateCertificateLookups < ActiveRecord::Migration
  def self.up
    create_table :certificate_lookups, force: true do |t|
      t.text      :certificate
      t.string    :serial
      t.string    :common_name
      t.datetime  :expires_at

      t.timestamps
    end
  end

  def self.down
    drop_table :certificate_lookups
  end
end
