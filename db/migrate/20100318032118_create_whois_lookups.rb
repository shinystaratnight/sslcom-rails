class CreateWhoisLookups < ActiveRecord::Migration
  def self.up
    create_table :whois_lookups, force: true do |t|
      t.references  :csr
      t.text        :raw
      t.string      :status
      t.datetime    :record_created_on, :expiration
      t.timestamps
    end
  end

  def self.down
    drop_table :whois_lookups
  end
end
