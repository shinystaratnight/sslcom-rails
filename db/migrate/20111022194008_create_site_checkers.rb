class CreateSiteChecks < ActiveRecord::Migration
  def self.up
    create_table :site_checks do |t|
      t.text :url
      t.text :ssl_certificate
      t.datetime :expires_at

      t.timestamps
    end
  end

  def self.down
    drop_table :site_checks
  end
end
